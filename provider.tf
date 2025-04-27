terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.31.0" # AWS provider version, not terraform version
    }
  }

  backend "s3" {
    bucket = "jp-k8-practice"
    key    = "eksctl"
    region = "us-east-1"
    dynamodb_table = "jp-k8-locking"
  }
}

provider "aws" {
  region = "us-east-1"
}