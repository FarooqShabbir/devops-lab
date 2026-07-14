terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # For a solo lab project, local state is fine. If you want remote state
  # later (recommended once anyone else touches this), uncomment and point
  # at an S3 bucket + DynamoDB lock table you create once, out of band:
  #
  # backend "s3" {
  #   bucket         = "farooq-devops-lab-tfstate"
  #   key            = "devops-lab/terraform.tfstate"
  #   region         = "eu-north-1"
  #   dynamodb_table = "devops-lab-tf-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region
}
