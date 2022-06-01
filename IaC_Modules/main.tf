# PROVIDER
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# REGION
provider "aws" {
    region                  = "${var.aws_region}"
    shared_credentials_file = ".aws/credentials"
}

# MODULES
module "vpc" {
    source          = "./modules/vpc"
    vpc_cidr        = "10.0.0.0/16"
    sn_pub_1a_cidr  = "10.0.1.0/24"
    sn_pub_1c_cidr  = "10.0.2.0/24"
    sn_priv_1a_cidr = "10.0.3.0/24"
    sn_priv_1c_cidr = "10.0.4.0/24"
}

module "rds" {
    source            = "./modules/rds"
    sn_priv_1a_id     = "${module.vpc.sn_priv_1a_id}"
    sn_priv_1c_id     = "${module.vpc.sn_priv_1c_id}"
    sg_priv_id        = "${module.ec2.sg_priv_id}"
    family            = "mysql8.0"
    instance_class    = "db.t2.micro"
    storage_type      = "gp2"
    allocated_storage =  20
    db_name           = "notifier"
}

module "ec2" {
    source           = "./modules/ec2"
    vpc_id           = "${module.vpc.vpc_id}"
    ami              = "ami-02e136e904f3da870"
    instance_type    = "t2.micro"
    sn_pub_1a_id     = "${module.vpc.sn_pub_1a_id}"
    sn_pub_1c_id     = "${module.vpc.sn_pub_1c_id}"
    sg_priv_id       = "${var.sg_priv_id}"
    desired_capacity = 4
    min_size         = 4
    max_size         = 8
    rds_endpoint     = "${module.rds.rds_endpoint}"
    rds_user         = "admin"
    rds_password     = "adminpwd"
    rds_name         = "notifier"
}