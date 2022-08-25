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


########################
# Bucket creation
########################

resource "aws_s3_bucket" "testetfs3" {
  bucket = "${var.bucket_name}"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

##########################
# Bucket private access
##########################
resource "aws_s3_bucket_acl" "testetfs3_acl" {
  bucket = aws_s3_bucket.testetfs3.id
  acl    = "public-read"

}

#############################
# Enable bucket versioning
#############################
resource "aws_s3_bucket_versioning" "testetfs3_versioning" {
  bucket = aws_s3_bucket.testetfs3.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_object" "object1" {
  bucket = aws_s3_bucket.testetfs3.id
  key    = "someobject"
  source = "index.html"
}