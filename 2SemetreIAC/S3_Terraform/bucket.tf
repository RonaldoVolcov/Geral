#########################################################################    
                  #CONFIGURAÇÃO PROVIDER/REGIÃO#
#########################################################################


#####################
#Config Provider AWS#
#####################


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}


#############################
#Config Região e Credenciais#
#############################

provider "aws" {
    #region                  = "${var.aws_region}"
    #shared_credentials_file = "${var.credential_file}"
    region                  = "us-east-1"
    shared_credentials_file = ".aws/credentials"
}

#Criação do Bucket S3

resource "aws_s3_bucket" "demoS3" {
  bucket = " Teste criação bucket S3"
}

##Config ACL

resource "aws_s3_bucket" "demoS3" {
    acl = "public-read"
}