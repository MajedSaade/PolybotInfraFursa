terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.55"
    }
  }

  required_version = ">= 1.7.0"

  backend "s3" {
    bucket = "majed-tf-backend"
    key    = "tfstate.json"
    region = "us-west-2"
  }

}
provider "aws" {
  region = var.region
}

# VPC module in root
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "majed_k8s-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = false

  tags = {
    Env = var.env
  }
}



# Kubernetes cluster infra module
module "k8s_cluster" {
  source = "./modules/k8s-cluster"

  env                 = var.env
  region              = var.region
  ami_id              = var.ami_id
  public_subnet       = module.vpc.public_subnets[0]
  vpc_id              = module.vpc.vpc_id
  vpc_subnet_ids      = module.vpc.public_subnets
  key_name            = var.key_name
  worker_ami_id       = var.worker_ami_id
  instance_profile_name = "k8s-worker-profile-${var.env}"
  account_id          = var.account_id
}

module "alb" {
  source = "./modules/alb"

  env                = var.env
  vpc_id             = var.vpc_id
  public_subnet_ids  = var.public_subnet[1]

  # from your cluster module output:
  worker_asg_name    = module.k8s_cluster.worker_asg_name

  ingress_nodeport   = var.ingress_nodeport
  certificate_arn    = var.certificate_arn
  allowed_ingress_cidrs = var.allowed_ingress_cidrs
  health_check_path  = var.health_check_path
  enable_http_redirect = true

  # Optional DNS
  route53_zone_id = var.route53_zone_id
  record_name     = var.record_name

  tags = var.tags
}
