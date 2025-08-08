#######################################
# Environment & AWS Basics
#######################################
variable "env" {
  type        = string
  description = "Deployment environment (e.g., dev, prod)"
}

variable "region" {
  type        = string
  description = "AWS region for deployment"
}

variable "account_id" {
  type        = string
  description = "AWS account ID used in IAM policy"
}

#######################################
# AMIs & Instance Types
#######################################
variable "ami_id" {
  type        = string
  description = "AMI ID for the control plane node"
}

variable "worker_ami_id" {
  type        = string
  description = "AMI ID for worker nodes"
}

variable "worker_instance_type" {
  type        = string
  description = "Instance type for worker nodes"
  default     = "t3.medium"
}

#######################################
# Networking (CIDRs & IDs)
#######################################
variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones to use"
}

variable "private_subnets" {
  type        = list(string)
  description = "CIDR blocks for private subnets"
}

variable "public_subnets" {
  type        = list(string)
  description = "CIDR blocks for public subnets"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID created by the VPC module"
}

variable "vpc_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for the worker ASG"
}

variable "public_subnet" {
  type        = string
  description = "Single public subnet ID for the control plane instance"
}

#######################################
# ALB-specific Networking
#######################################
variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs for the ALB"
}

#######################################
# IAM & Access
#######################################
variable "key_name" {
  type        = string
  description = "EC2 SSH key pair name"
}

variable "instance_profile_name" {
  type        = string
  description = "IAM instance profile name for the worker nodes"
}

#######################################
# ALB & Ingress Settings
#######################################
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

#######################################
# Tags
#######################################
variable "tags" {
  type        = map(string)
  default     = {}
}
