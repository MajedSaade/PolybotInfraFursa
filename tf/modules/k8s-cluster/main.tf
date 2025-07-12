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

# Control Plane IAM Role
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

# IAM Policy to PUT join command
resource "aws_iam_policy" "ssm_put_join_command" {
  name = "SSMPutJoinCommand-${var.env}"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "ssm:PutParameter",
      Resource = "arn:aws:ssm:${var.region}:${var.account_id}:parameter/k8s/worker/join-command"
    }]
  })
}

# IAM Policy to READ SSM secrets for Polybot
resource "aws_iam_policy" "ssm_read_polybot_secrets" {
  name = "SSMReadPolybotSecrets-${var.env}"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParameterHistory"
      ],
      Resource = "arn:aws:ssm:${var.region}:${var.account_id}:parameter/polybot/*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_ssm_put" {
  role       = aws_iam_role.control_plane_role.name
  policy_arn = aws_iam_policy.ssm_put_join_command.arn
}

resource "aws_iam_role_policy_attachment" "attach_ssm_read_secrets" {
  role       = aws_iam_role.control_plane_role.name
  policy_arn = aws_iam_policy.ssm_read_polybot_secrets.arn
}

# IAM Policy to read kubeadm script from S3
resource "aws_iam_policy" "s3_read_kubeadm_script" {
  name = "S3ReadKubeadmScript-${var.env}"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = ["s3:GetObject"],
      Resource = "arn:aws:s3:::majed-tf-backend/scripts/kubeadm-init.sh"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_s3_read" {
  role       = aws_iam_role.control_plane_role.name
  policy_arn = aws_iam_policy.s3_read_kubeadm_script.arn
}

# Control Plane Instance Profile
resource "aws_iam_instance_profile" "control_plane_profile" {
  name = "majed-k8s-control-plane-profile-${var.env}"
  role = aws_iam_role.control_plane_role.name
}

# ⛅ Control Plane EC2 Instance
resource "aws_instance" "control_plane" {
  ami                         = var.ami_id
  instance_type               = "t3.medium"
  subnet_id                   = var.public_subnet
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.control_plane_sg.id]
  key_name                    = "Majed_Discord_key"

  iam_instance_profile        = aws_iam_instance_profile.control_plane_profile.name
  user_data                   = file("${path.module}/scripts/control_plane_userdata.sh")

  tags = {
    Name = "Majed-control-plane-${var.env}"
    Role = "control-plane"
  }
}
