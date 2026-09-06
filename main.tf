terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

module "vpc" {
  source = "./modules/vpc"
}

module "alb" {
  source            = "./modules/alb"
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
}

module "asg" {
  source                = "./modules/asg"
  vpc_id                = module.vpc.vpc_id
  alb_security_group_id = module.alb.alb_security_group_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  target_group_arn      = module.alb.target_group_arn
}

module "rds" {
  source                = "./modules/rds"
  vpc_id                = module.vpc.vpc_id
  db_subnet_group_name  = module.vpc.db_subnet_group_name
  ec2_security_group_id = module.asg.instance_security_group_id
  db_password           = var.db_password
}

module "monitoring" {
  source      = "./modules/monitoring"
  alert_email = var.alert_email
  asg_name    = module.asg.asg_name
}
