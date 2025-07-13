resource "aws_ec2_tag" "cluster_shared_tag" {
  for_each    = toset(var.vpc_subnet_ids)
  resource_id = each.value
  key         = "kubernetes.io/cluster/fursa-k8s"
  value       = "shared"
}

resource "aws_ec2_tag" "elb_tag" {
  for_each    = toset(var.vpc_subnet_ids)
  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

resource "aws_iam_policy" "alb_controller_policy" {
  name   = "AWSLoadBalancerControllerIAMPolicy"
  policy = file("${path.module}/alb-controller-policy.json")
}

resource "aws_iam_role_policy_attachment" "alb_attach_policy" {
  role       = aws_iam_role.control_plane_role.name
  policy_arn = aws_iam_policy.alb_controller_policy.arn
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "helm_release" "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.8.1"

  set {
    name  = "clusterName"
    value = "majed-k8s"
  }

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "image.repository"
    value = "602401143452.dkr.ecr.${var.region}.amazonaws.com/amazon/aws-load-balancer-controller"
  }
}


# ⛅ Control Plane Security Group
resource "aws_security_group" "control_plane_sg" {
  name        = "majed-control-plane-sg-${var.env}"
  description = "Allow SSH and Kubernetes traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "majed-control-plane-sg-${var.env}"
  }
}

resource "aws_iam_role" "control_plane_role" {
  name = "majed-k8s-control-plane-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "ssm_put_join_command" {
  name = "SSMPutJoinCommand-${var.env}"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "ssm:PutParameter",
        Resource = "arn:aws:ssm:${var.region}:${var.account_id}:parameter/k8s/worker/join-command"
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:Describe*",
          "ec2:CreateTags",
          "elasticloadbalancing:*"
        ],
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "attach_ssm_put" {
  role       = aws_iam_role.control_plane_role.name
  policy_arn = aws_iam_policy.ssm_put_join_command.arn
}

resource "aws_iam_instance_profile" "control_plane_profile" {
  name = "majed-k8s-control-plane-profile-${var.env}"
  role = aws_iam_role.control_plane_role.name
}

resource "aws_iam_policy" "s3_read_kubeadm_script" {
  name = "S3ReadKubeadmScript-${var.env}"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["s3:GetObject"],
        Resource = "arn:aws:s3:::majed-tf-backend/scripts/kubeadm-init.sh"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_s3_read" {
  role       = aws_iam_role.control_plane_role.name
  policy_arn = aws_iam_policy.s3_read_kubeadm_script.arn
}


# ⛅ Control Plane EC2 Instance
resource "aws_instance" "control_plane" {
  ami                         = var.ami_id
  instance_type               = "t3.large"
  subnet_id                   = var.public_subnet
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.control_plane_sg.id]
  key_name                    = "Majed_Discord_key"

  iam_instance_profile        = aws_iam_instance_profile.control_plane_profile.name

  user_data = file("${path.module}/scripts/control_plane_userdata.sh")

    root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "Majed-control-plane-${var.env}"
    Role = "control-plane"
  }
}

# ⛅ Worker Node Security Group
resource "aws_security_group" "worker_sg" {
  name        = "majed-worker-sg-${var.env}"
  description = "Security group for Kubernetes worker nodes"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow kubelet and node-to-node communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow control plane to schedule pods and communicate"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH for debugging"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "majed-worker-sg-${var.env}"
  }
}

# ✅ IAM for Worker Node EC2s
resource "aws_iam_role" "worker_role" {
  name = "majed-k8s-worker-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "ssm_read_join_command" {
  name   = "SSMReadJoinCommandPolicy-${var.env}"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["ssm:GetParameter"],
        Resource = "arn:aws:ssm:${var.region}:${var.account_id}:parameter/k8s/worker/join-command"
      },
      {
        Effect   = "Allow",
        Action   = ["kms:Decrypt"],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_ssm_read" {
  role       = aws_iam_role.worker_role.name
  policy_arn = aws_iam_policy.ssm_read_join_command.arn
}

resource "aws_iam_instance_profile" "worker_profile" {
  name = "majed-k8s-worker-profile-${var.env}"
  role = aws_iam_role.worker_role.name
}

# 🚀 Launch Template for Worker Nodes
resource "aws_launch_template" "worker_lt" {
  name_prefix   = "majed-k8s-worker-"
  image_id      = var.worker_ami_id
  instance_type = var.worker_instance_type
  key_name      = var.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.worker_profile.name
  }

  user_data = base64encode(file("${path.module}/scripts/worker-user-data.sh"))

   block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 20
      volume_type = "gp3"
    }
  }


  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.worker_sg.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "majed-k8s-worker-node"
    }
  }
}

# 🔁 Auto Scaling Group for Workers
resource "aws_autoscaling_group" "worker_asg" {
  name                      = "majed-k8s-worker-asg"
  desired_capacity          = 2
  min_size                  = 1
  max_size                  = 4
  vpc_zone_identifier       = var.vpc_subnet_ids
  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.worker_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "majed-k8s-worker-node"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# 🔐 Calico BGP/IPIP Rules
resource "aws_security_group_rule" "cp_allow_bgp_from_workers" {
  type                     = "ingress"
  from_port                = 179
  to_port                  = 179
  protocol                 = "tcp"
  security_group_id        = aws_security_group.control_plane_sg.id
  source_security_group_id = aws_security_group.worker_sg.id
  description              = "Allow BGP (TCP 179) from workers"
}

resource "aws_security_group_rule" "cp_allow_ipip_from_workers" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "4"
  security_group_id        = aws_security_group.control_plane_sg.id
  source_security_group_id = aws_security_group.worker_sg.id
  description              = "Allow IP-in-IP (Protocol 4) from workers"
}

resource "aws_security_group_rule" "worker_allow_bgp_from_cp" {
  type                     = "ingress"
  from_port                = 179
  to_port                  = 179
  protocol                 = "tcp"
  security_group_id        = aws_security_group.worker_sg.id
  source_security_group_id = aws_security_group.control_plane_sg.id
  description              = "Allow BGP (TCP 179) from control plane"
}

resource "aws_security_group_rule" "worker_allow_ipip_from_cp" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "4"
  security_group_id        = aws_security_group.worker_sg.id
  source_security_group_id = aws_security_group.control_plane_sg.id
  description              = "Allow IP-in-IP (Protocol 4) from control plane"
}

resource "aws_iam_policy" "eso_ssm_access" {
  name = "ESOSecretAccess-${var.env}"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParameterHistory"],
        Resource = "arn:aws:ssm:${var.region}:${var.account_id}:parameter/polybot/${var.env}/DISCORD_BOT_TOKEN"
      }
    ]
  })
}
