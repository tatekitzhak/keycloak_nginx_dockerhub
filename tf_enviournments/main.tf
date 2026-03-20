terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.1.7"

  ##
  # Updated to match your first error fix:
  ##

  # required_version = ">= 1.4.0" 

}

provider "aws" {
  region = "us-east-2"
}


module "vpc" {
  source   = "./modules/vpc"
  vpc_cidr = var.vpc_cidr
}

module "sg" {
  source = "./modules/sg"
  vpc_id = module.vpc.vpc_id
}

module "ec2" {
  source = "./modules/ec2"
  vpc_id = module.vpc.vpc_id
  sg_id  = module.sg.security_group_id
}

output "ec2_instance_id" {
  description = "EC2 instance ID for CD deploy (SSM); use in workflow or secret EC2_INSTANCE_ID"
  value       = module.ec2.ec2_instance_id
}

data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "caller_arn" {
  value = data.aws_caller_identity.current.arn
}

output "caller_user_id" {
  value = data.aws_caller_identity.current.user_id
}

resource "null_resource" "create_file_localy" {
  provisioner "local-exec" {

    command = <<EOT
                  echo 'AWS User Account Info : ${jsonencode(data.aws_caller_identity.current)}\n' > aws_user_account_info.txt
                EOT
  }
}
