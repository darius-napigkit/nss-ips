# Define the AWS Provider and Terraform version constraints, and backend location
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "nss-terraform-state-0001a"
    key            = "dev/nss-ips/liveprojects/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "tf-state-lock-table-dev"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-west-2"
}
