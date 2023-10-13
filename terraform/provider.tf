terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.15.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "roboshop-remote-state27"
    key    = "Roboshop-catalogue-DEV"
    region = "us-east-1"
    dynamodb_table = "Roboshop-Lock"
  }
}