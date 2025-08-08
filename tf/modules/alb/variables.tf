############################
# modules/alb/variables.tf
############################

variable "env" {
  type        = string
  description = "Environment suffix for naming (e.g., dev/prod)"
}

variable "vpc_id" {
  type        = string
  description = "VPC where the ALB and worker nodes reside"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs for the ALB"
}

variable "worker_asg_name" {
  type        = string
  description = "Name of the worker nodes Auto Scaling Group"
}

variable "ingress_nodeport" {
  type        = number
  description = "NodePort of the Nginx Ingress Service (e.g., 30080)"
}

variable "certificate_arn" {
  type        = string
  description = "ACM certificate ARN for HTTPS"
}

variable "allowed_ingress_cidrs" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "CIDRs allowed to access ALB 80/443 (restrict to Telegram CIDRs to harden)"
}

variable "health_check_path" {
  type        = string
  default     = "/healthz"
  description = "HTTP path for ALB health checks"
}

variable "enable_http_redirect" {
  type        = bool
  default     = true
  description = "Create HTTP:80 listener that redirects to HTTPS:443"
}

variable "route53_zone_id" {
  type        = string
  default     = null
  description = "Route53 Hosted Zone ID (optional)"
}

variable "record_name" {
  type        = string
  default     = null
  description = "DNS record name like polybot.fursa.click (optional)"
}

variable "tags" {
  type        = map(string)
  default     = {}
}
