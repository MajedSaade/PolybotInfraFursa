############################
# modules/alb/main.tf
############################

# --- Security Group for ALB ---
resource "aws_security_group" "this" {
  name        = "polybot-alb-sg-${var.env}"
  description = "ALB SG for Polybot/YOLO"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_ingress_cidrs
  }

  ingress {
    description = "HTTP (redirect to HTTPS)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_ingress_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({ Name = "polybot-alb-sg-${var.env}" }, var.tags)
}

# --- Application Load Balancer ---
resource "aws_lb" "this" {
  name               = "polybot-alb-${var.env}"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = [aws_security_group.this.id]
  idle_timeout       = 60
  enable_deletion_protection = false

  tags = merge({ Name = "polybot-alb-${var.env}" }, var.tags)
}

# --- Target Group (instance targets: worker nodes) ---
resource "aws_lb_target_group" "this" {
  name        = "polybot-ingress-tg-${var.env}"
  port        = var.ingress_nodeport
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 15
    timeout             = 5
    protocol            = "HTTP"
    path                = var.health_check_path
    matcher             = "200-399"
    port                = "traffic-port"
  }

  tags = merge({ Name = "polybot-ingress-tg-${var.env}" }, var.tags)
}

# --- Attach worker ASG to Target Group ---
data "aws_autoscaling_group" "workers" {
  name = var.worker_asg_name
}

resource "aws_autoscaling_attachment" "asg_tg" {
  autoscaling_group_name = data.aws_autoscaling_group.workers.name
  lb_target_group_arn    = aws_lb_target_group.this.arn
}

# --- HTTPS Listener 443 ---
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.certificate_arn
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# --- HTTP Listener 80 -> redirect to 443 (optional) ---
resource "aws_lb_listener" "http" {
  count             = var.enable_http_redirect ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# --- (Optional) Route53 alias ---
resource "aws_route53_record" "alias" {
  count   = var.record_name != null && var.route53_zone_id != null ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.record_name
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}
