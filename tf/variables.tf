variable "env" {
  type        = string
  description = "Deployment environment (e.g., dev, prod)"
}

variable "region" {
  type        = string
  description = "AWS region for deployment"
}

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

variable "key_name" {
  type        = string
  description = "EC2 SSH key pair name"
}

variable "instance_profile_name" {
  type        = string
  description = "IAM instance profile name for the worker nodes"
}

variable "account_id" {
  type        = string
  description = "AWS account ID used in IAM policy"
}
