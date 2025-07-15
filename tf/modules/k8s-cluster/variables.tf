variable "env" {
  type = string
}

variable "region" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "public_subnet" {
  description = "Subnet for control plane"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for associating SG"
  type        = string
}
variable "worker_ami_id" {
  type        = string
  description = "AMI ID for worker nodes"
}

variable "worker_instance_type" {
  type        = string
  description = "EC2 instance type for worker nodes"
  default     = "t3.large"
}

variable "key_name" {
  type        = string
  description = "SSH key pair name"
}

variable "instance_profile_name" {
  type        = string
  description = "IAM instance profile name for worker nodes"
}

variable "vpc_subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for the Auto Scaling Group"
}
variable "account_id" {
  type        = string
  description = "AWS Account ID used in IAM policy to access SSM parameter"
}

variable "domain_name" {
  description = "The Route53 hosted domain name (e.g., majed-k8s.click)"
  type        = string
}
variable "subdomain" {
  description = "Subdomain to use for Polybot ingress"
  type        = string
}

