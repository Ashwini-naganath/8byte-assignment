terraform {
  required_version = ">= 1.6.0"

  backend "s3" {
    bucket       = "8byte-devops-terraform-state-2026"
    key          = "devops-assignment/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
