#################
#Config Provider#
#################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

###############
#Config Região#
###############

provider "aws" {
    region = "us-east-1"
    shared_credentials_file = ".aws/credentials"
}
#####################
#Criação da Work VPC#
#####################

resource "aws_vpc" "vpc10" {
    cidr_block           = "10.0.0.0/16"
    enable_dns_hostnames = "true"

    tags = {
        Name = "Name VPC 10"  
    }
}

##########################
#Criação Internet Gateway#
##########################

resource "aws_internet_gateway" "igw_vpc10" {
    vpc_id = aws_vpc.vpc10.id

    tags = {
        Name = "Internet Gateway VPC 10"
    }
}

#########################
#Criação Subnet Publicas#
#########################

resource "aws_subnet" "sn_vpc10_pub_1a" {
    vpc_id                  = aws_vpc.vpc10.id
    cidr_block              = "10.0.1.0/24"
    map_public_ip_on_launch = "true"
    availability_zone       = "us-east-1a"

    tags = {
        Name = "Public Subnet East 1A"
    }
}

resource "aws_subnet" "sn_vpc10_pub_1c" {
    vpc_id                  = aws_vpc.vpc10.id
    cidr_block              = "10.0.2.0/24"
    map_public_ip_on_launch = "true"
    availability_zone       = "us-east-1c"

    tags = {
        Name = "Public Subnet East 1C"
    }
}


########################
#Criação Subnet Privada#
########################

resource "aws_subnet" "sn_vpc10_priv_1a" {
    vpc_id                  = aws_vpc.vpc10.id
    cidr_block              = "10.0.3.0/24"
    map_public_ip_on_launch = "true"
    availability_zone       = "us-east-1a"

    tags = {
        Name = "Private Subnet East 1A"
    }
}

resource "aws_subnet" "sn_vpc10_priv_1c" {
    vpc_id                  = aws_vpc.vpc10.id
    cidr_block              = "10.0.4.0/24"
    map_public_ip_on_launch = "true"
    availability_zone       = "us-east-1c"

    tags = {
        Name = "Private Subnet East 1C"
    }
}



############################
#Criação Public Route Table#
############################

resource "aws_route_table" "Public_Route_Table" {
    vpc_id = aws_vpc.vpc10.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw_vpc10.id
    }

    tags = {
        Name = "Public Route Table"
    }
}

#############################
#Criação Private Route Table#
#############################

resource "aws_route_table" "Private_Route_Table" {
    vpc_id = aws_vpc.vpc10.id

    tags = {
        Name = "Private Route Table"
    }
}

#############################
#Associação da Public Subnet#
#############################

resource "aws_route_table_association" "Assoc_1_Pub_a" {

  subnet_id      = aws_subnet.sn_vpc10_pub_1a.id
  route_table_id = aws_route_table.Public_Route_Table.id

}

resource "aws_route_table_association" "Assoc_1_Pub_c" {

  subnet_id      = aws_subnet.sn_vpc10_pub_1c.id
  route_table_id = aws_route_table.Public_Route_Table.id

}

##############################
#Associação da Private Subnet#
##############################

resource "aws_route_table_association" "Assoc_2_Priv_a" {

  subnet_id      = aws_subnet.sn_vpc10_priv_1a.id
  route_table_id = aws_route_table.Private_Route_Table.id

}

resource "aws_route_table_association" "Assoc_2_Priv_c" {

  subnet_id      = aws_subnet.sn_vpc10_priv_1c.id
  route_table_id = aws_route_table.Private_Route_Table.id

}

################################
#Grupos de Segurança Plublic SN#
################################

resource "aws_security_group" "sg_vpc10_pub" {

    name        = "Public_Security_Group"
    description = "Grupo de Seguranca Public Network"
    vpc_id      = aws_vpc.vpc10.id
    
    egress {
        description = "All to All"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "All from 10.0.0.0/16"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["10.0.0.0/16"]
    }
    
    ingress {
        description = "TCP/22 from All"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    ingress {
        description = "TCP/80 from All"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "Security Group Public SN"
    }
}

################################
#Grupos de Segurança Private SN#
################################

resource "aws_security_group" "sg_vpc10_priv" {

    name        = "Private_Security_Group"
    description = "Grupo de Seguranca Private Network"
    vpc_id      = aws_vpc.vpc10.id
    
    egress {
        description = "All to All"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "All from 10.0.0.0/16"
        from_port   = 3306 ##Porta RDS##
        to_port     = 3306
        protocol    = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
    }
    
    tags = {
        Name = "Security Group Private SN"
    }
}

#########################################################################    
                        #CONFIG DATABASE#
#########################################################################


#########################
#DATABASE - Subnet Group#
#########################

resource "aws_db_subnet_group" "sg_vpc10_rds"{

    name       = "sg-vpc10-rds"
    subnet_ids = [ aws_subnet.sn_vpc10_priv_1a.id, aws_subnet.sn_vpc10_priv_1c.id ]

    tags = {
        Name = "Subnet RDS to Priv Subnet AZ 1a - 1c"
    }
}

##############################
##DATABASE - PARAMETER GROUP##
##############################

resource "aws_db_parameter_group" "pg_vpc10_db_rds" {
    name   = "pg-vpc10-db-rds"
    family = "mysql8.0"
    
    parameter {
        name  = "character_set_server"
        value = "utf8"
    }
    
    parameter {
        name  = "character_set_database"
        value = "utf8"
    }
}


###########################
##DATABASE - INSTANCE RDS##
###########################

resource "aws_db_instance" "rds_db_notifier" {
    identifier             = "rds-db-notifier"
    engine                 = "mysql"
    engine_version         = "8.0.23"
    instance_class         = "db.t3.small"
    storage_type           = "gp2"
    allocated_storage      = "20"
    max_allocated_storage  = 0
    monitoring_interval    = 0
    name                   = "notifier"
    username               = "admin"
    password               = "adminpwd"
    skip_final_snapshot    = true
    db_subnet_group_name   = aws_db_subnet_group.sg_vpc10_rds.name
    parameter_group_name   = aws_db_parameter_group.pg_vpc10_db_rds.name
    vpc_security_group_ids = [ aws_security_group.sg_vpc10_priv.id  ]

    tags = {
        Name = "RDS Notifier"
    }
}

#########################################################################    
                        #CONFIG EC2 APPLICATION PHP#
#########################################################################

# EC2 LAUNCH TEMPLATE
data "template_file" "user_data" {
    template = "${file(".script/userdata-notifier.sh")}"
}


resource "aws_launch_template" "lt_app_notify" {
    name                   = "lt_app_notify"
    image_id               = "ami-02e136e904f3da870"
    instance_type          = "t2.micro"
    vpc_security_group_ids = [aws_security_group.sg_vpc10_pub.id]
    key_name               = "key"
    user_data              = "${base64encode(data.template_file.user_data.rendered)}"


    tag_specifications {
        resource_type = "instance"
        tags = {
            Name = "app_notify"
        }
    }

    tags = {
        Name = "lt_app_notify"
    }
}

# APPLICATION LOAD BALANCER
resource "aws_lb" "lb_app_notify" {
    name               = "lb-app-notify"
    load_balancer_type = "application"
    subnets            = [aws_subnet.sn_vpc10_pub_1a.id, aws_subnet.sn_vpc10_pub_1c.id]
    security_groups    = [aws_security_group.sg_vpc10_pub.id]
    
    tags = {
        Name = "lb_app_notify"
    }
}

# APPLICATION LOAD BALANCER TARGET GROUP
resource "aws_lb_target_group" "tg_app_notify" {
    vpc_id   = aws_vpc.vpc10.id
    
    name     = "tg-app-notify"
    protocol = "HTTP"
    port     = "80"

    tags = {
        Name = "tg_app_notify"
    }
}

# APPLICATION LOAD BALANCER LISTENER
resource "aws_lb_listener" "listener_app_notify" {
    load_balancer_arn = aws_lb.lb_app_notify.arn
    protocol          = "HTTP"
    port              = "80"
    
    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.tg_app_notify.arn
    }
}

# AUTO SCALING GROUP
resource "aws_autoscaling_group" "asg_app_notify" {
    name                = "asg_app_notify"
    vpc_zone_identifier = [aws_subnet.sn_vpc10_pub_1a.id, aws_subnet.sn_vpc10_pub_1c.id]
    desired_capacity    = "2"
    min_size            = "1"
    max_size            = "4"
    target_group_arns   = [aws_lb_target_group.tg_app_notify.arn]

    launch_template {
        id      = aws_launch_template.lt_app_notify.id
        version = "$Latest"
    }
   
}