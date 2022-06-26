/*
Autor: Ronaldo Euclides Volcov RM84422 - Global Solution IaC
*/

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
    region = "us-east-1"
    shared_credentials_file = ".aws/credentials"

}

#########################################################################    
                        #CONFIGURAÇÃO DA REDE#
#########################################################################

###################
#Criação da VPC 10#
###################

resource "aws_vpc" "vpc10" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = "true"

  tags = {
    "Name" = "vpc10"
  }
}

###################
#Criação da VPC 20#
###################

resource "aws_vpc" "vpc20" {
  cidr_block           = "20.0.0.0/16"
  enable_dns_hostnames = "true"

  tags = {
    "Name" = "vpc20"
  }
}

####################################
#Criação Internet Gateway p/ VPC 10#
####################################

resource "aws_internet_gateway" "igw_vpc10" {
  vpc_id = aws_vpc.vpc10.id

  tags = {
    "Name" = "igw_vpc10"
  }
}

###########################################################  
                #CRIAÇÃO DAS SUBNETES#
###########################################################

##################################
#Criação da Subnet Publica VPC 10#
##################################

resource "aws_subnet" "sn_vpc10" {
  vpc_id                  = aws_vpc.vpc10.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "us-east-1a"

  tags = {
    "Name" = "sn_vpc10"
  }
}

##################################
#Criação da Subnet Privada VPC 20#
##################################

resource "aws_subnet" "sn_vpc20" {
  vpc_id                  = aws_vpc.vpc20.id
  cidr_block              = "20.0.1.0/24"
  availability_zone       = "us-east-1a"

  tags = {
    "Name" = "sn_vpc20"
  }
}


#############
#VPC PEERING#
#############
resource "aws_vpc_peering_connection" "vpc_peering" {
  peer_vpc_id = aws_vpc.vpc10.id
  vpc_id      = aws_vpc.vpc20.id
  auto_accept = true

  tags = {
    "Name" = "vpc_peering"
  }
}

#########################################################################    
                #CONFIGURAÇÃO DAS TABELAS DE ROTEAMENTO#
#########################################################################


#######################   
#CONFIGURAÇÃO RT SN 10#
#######################

resource "aws_route_table" "rt_vpc10" {
  vpc_id = aws_vpc.vpc10.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_vpc10.id
  }

  route {
    cidr_block = "20.0.0.0/16"
    gateway_id = aws_vpc_peering_connection.vpc_peering.id
  }

  tags = {
    "Name" = "rt_vpc10"
  }
}

#######################   
#CONFIGURAÇÃO RT SN 20#
#######################

resource "aws_route_table" "rt_vpc20" {
  vpc_id = aws_vpc.vpc20.id

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = aws_vpc_peering_connection.vpc_peering.id
  }

  tags = {
    "Name" = "rt_vpc20"
  }
}

##################################
#Associação Tabela de Roteamentoa#
##################################

resource "aws_route_table_association" "Assoc_VPC_10" {
  subnet_id      = aws_subnet.sn_vpc10.id
  route_table_id = aws_route_table.rt_vpc10.id
}

resource "aws_route_table_association" "Assoc_VPC_20" {
  subnet_id      = aws_subnet.sn_vpc20.id
  route_table_id = aws_route_table.rt_vpc20.id
}


