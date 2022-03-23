#PROVIDER

terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 3.0"

        }
    }
}

#REGION

provider "aws" {
    region = "us-east-1"
    share_credentials_file = ".aws/credentials"
}