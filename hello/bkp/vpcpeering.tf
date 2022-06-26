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
        Name = "igw_vpc10"
    }
}

#########################################################################    
                #CRIAÇÃO DAS SUBNETES PRIVADA E PUBLICA#
#########################################################################


###########################
#Criação da Subnet Privada#
###########################

resource "aws_subnet" "sn_vpc10" {
    vpc_id                  = aws_vpc.vpc10.id
    cidr_block              = "10.0.1.0/24"
    map_public_ip_on_launch = "false"
    availability_zone       = "us-east-1a" ##AZ

    tags = {
        Name = "sn_vpc10"
    }
}

resource "aws_subnet" "sn_vpc20" {
    vpc_id                  = aws_vpc.vpc20.id
    cidr_block              = "20.0.4.0/24"
    map_public_ip_on_launch = "false"
    availability_zone       = "us-east-1a" ##AZ

    tags = {
        Name = "sn_vpc20"
    }
}

#########################################################################    
                #CONFIGURAÇÃO DAS TABELAS DE ROTEAMENTO#
#########################################################################

##############################################
#Criação da tabela de roteamento Rede Publica#
##############################################

resource "aws_route_table" "rt_vpc10" {
    vpc_id = aws_vpc.vpc10.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw_vpc10.id
    }

    tags = {
        Name = "rt_vpc10"
    }
}

resource "aws_route_table" "rt_vpc20" {
    vpc_id = aws_vpc.vpc20.id

    tags = {
        Name = "rt_vpc20"
    }
}

################################################
#Associação Tabela de Roteamento a Rede Publica#
################################################

resource "aws_route_table_association" "Assoc_1_Pub_a" {

  subnet_id      = aws_subnet.sn_vpc10_pub_1a.id
  route_table_id = aws_route_table.Public_Route_Table.id

}

resource "aws_route_table_association" "Assoc_1_Pub_c" {

  subnet_id      = aws_subnet.sn_vpc10_pub_1c.id
  route_table_id = aws_route_table.Public_Route_Table.id

}

################################################
#Associação Tabela de Roteamento a Rede Privada#
################################################

resource "aws_route_table_association" "Assoc_2_Priv_a" {

  subnet_id      = aws_subnet.sn_vpc10_priv_1a.id
  route_table_id = aws_route_table.Private_Route_Table.id

}

resource "aws_route_table_association" "Assoc_2_Priv_c" {

  subnet_id      = aws_subnet.sn_vpc10_priv_1c.id
  route_table_id = aws_route_table.Private_Route_Table.id

}

#########################################################################    
                    #CONFIGURAÇÃO DE SEGURAÇA DAS SUBNETES#
#########################################################################

##################################
#Grupos de Segurança Rede Publica#
##################################

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
        Name = "sg_vpc10_pub"
    }
}

##################################
#Grupos de Segurança Rede Privada#
##################################

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
        Name = "sg_vpc10_priv"
    }
}

#########################################################################    
                #CONFIGURAÇÃO DO BANCO DE DADOS RDS#
#########################################################################


################################
#Associação as Subnets Privadas#
################################

resource "aws_db_subnet_group" "sg_vpc10_db_rds"{

    name       = "sg-vpc10-rds"
    subnet_ids = [ aws_subnet.sn_vpc10_priv_1a.id, aws_subnet.sn_vpc10_priv_1c.id ]

    tags = {
        Name = "sg_vpc10_rds"
    }
}

###################################
##Parameter Group UTF8 para o PHP##
###################################

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
##Criaçao da Instancia RDS#
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
    db_subnet_group_name   = aws_db_subnet_group.sg_vpc10_db_rds.name
    parameter_group_name   = aws_db_parameter_group.pg_vpc10_db_rds.name
    vpc_security_group_ids = [ aws_security_group.sg_vpc10_priv.id  ]

    tags = {
        Name = "rds_db_notifier"
    }
}

#########################################################################    
                        #CONFIG EC2 APLICAÇÃO PHP#
#########################################################################

####################################################
##Template para criação de novas instancias de EC2##
####################################################S

data "template_file" "user_data" {
    template = "${file(".script/userdata-notifier.sh")}"
}


resource "aws_launch_template" "lt_app_notify" {
    name                   = "lt-app-notify"
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


#########################################################################    
            #CONFIGURAÇÃO LOAD BALANCER E AUTOSCALING#
#########################################################################

######################################################################
##Criação do ELB e Associaçao do ELB as Subnets e Grupo de Segurança##
######################################################################
resource "aws_lb" "elb_ws" {
    name               = "elb-ws"
    load_balancer_type = "application" #Aplicação estará escutando na porta 80 exposto pelos Apaches
    subnets            = [aws_subnet.sn_vpc10_pub_1a.id, aws_subnet.sn_vpc10_pub_1c.id] ##AZs Public Subnets
    security_groups    = [aws_security_group.sg_vpc10_pub.id] ##SG das Subnets

    
    tags = {
        Name = "elb_ws"
    }
}



############################
#Criação do Target Group####
############################

resource "aws_lb_target_group" "tg_elb_ws" {
    vpc_id   = aws_vpc.vpc10.id
    
    name     = "tg-elb-ws"
    protocol = "HTTP"
    port     = "80"

    health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    port                = 80
    interval            = 10

    }

    tags = {
        Name = "tg_elb_ws"
    }
}

##########################
#Config Listener Porta 80#
##########################

resource "aws_lb_listener" "listener_elb_ws" {
    load_balancer_arn = aws_lb.elb_ws.arn
    protocol          = "HTTP"
    port              = "80"
    
    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.tg_elb_ws.arn
    }
}

########################
#Criação do AutoScaling#
########################

resource "aws_autoscaling_group" "asg_ws" {
    name                = "asg-ws"
    vpc_zone_identifier = [aws_subnet.sn_vpc10_pub_1a.id, aws_subnet.sn_vpc10_pub_1c.id]
    desired_capacity    = "2"
    min_size            = "1"
    max_size            = "4"
    target_group_arns   = [aws_lb_target_group.tg_elb_ws.arn]

    launch_template {
        id      = aws_launch_template.lt_app_notify.id
        version = "$Latest"
    }
   
}


#########################################################################    
            #CONFIGURAÇÃO VPC ENDPOINT#
#########################################################################

resource "aws_vpc_endpoint" "vpc_ep_vpc10" {
  vpc_id            = aws_vpc.vpc10.id
  service_name      = "com.amazonaws.us-east-1.sns"
  vpc_endpoint_type = "Interface"
  security_group_ids    = [aws_security_group.sg_vpc10_pub.id] ##SG AutoScaling

  private_dns_enabled = true

  tags = {
        Name = "vpc_ep_vpc10"
    }
}
#########################################################################    
                        #CONFIGURAÇÃO SNS#
#########################################################################
locals {
  phone_numbers = ["+5511911112222"] ##Array para testar numero
}

resource "aws_sns_topic" "sn_app" {
  name            = "sn-app"
  delivery_policy = jsonencode({  ##Policy para envio do SMS
    "http" : {
      "defaultHealthyRetryPolicy" : {
        "minDelayTarget" : 20,
        "maxDelayTarget" : 20,
        "numRetries" : 3,
        "numMaxDelayRetries" : 0,
        "numNoDelayRetries" : 0,
        "numMinDelayRetries" : 0,
        "backoffFunction" : "linear"
      },
      "disableSubscriptionOverrides" : false,
      "defaultThrottlePolicy" : {
        "maxReceivesPerSecond" : 1
      }
    }
  })
}

resource "aws_sns_topic_subscription" "topic_sms_subscription" {
  count     = length(local.phone_numbers) ##Valida quantidade de campos
  topic_arn = aws_sns_topic.sn_app.arn
  protocol  = "sms"
  endpoint  = local.phone_numbers[count.index] ##Chamada do Array
}





/*

# PROVIDER
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# REGIAO
provider "aws" {
  region = "us-east-1"
}

# VPC'S
resource "aws_vpc" "vpc10" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = "true"

  tags = {
    "Name" = "vpc10"
  }
}

resource "aws_vpc" "vpc20" {
  cidr_block           = "20.0.0.0/16"
  enable_dns_hostnames = "true"

  tags = {
    "Name" = "vpc20"
  }
}

# INTERNET GATEWAY
resource "aws_internet_gateway" "igw_vpc10" {
  vpc_id = aws_vpc.vpc10.id

  tags = {
    "Name" = "igw_vpc10"
  }
}

resource "aws_internet_gateway" "igw_vpc20" {
  vpc_id = aws_vpc.vpc20.id

  tags = {
    "Name" = "igw_vpc20"
  }
}

# SUBNET'S
resource "aws_subnet" "sn_vpc10_public" {
  vpc_id                  = aws_vpc.vpc10.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "us-east-1a"

  tags = {
    "Name" = "sn_vpc10_public"
  }
}

resource "aws_subnet" "sn_vpc20_public" {
  vpc_id                  = aws_vpc.vpc20.id
  cidr_block              = "20.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "us-east-1a"

  tags = {
    "Name" = "sn_vpc20_public"
  }
}

resource "aws_subnet" "sn_vpc10_private" {
  vpc_id            = aws_vpc.vpc10.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1c"

  tags = {
    "Name" = "sn_vpc10_private"
  }
}

resource "aws_subnet" "sn_vpc20_private" {
  vpc_id            = aws_vpc.vpc20.id
  cidr_block        = "20.0.2.0/24"
  availability_zone = "us-east-1c"

  tags = {
    "Name" = "sn_vpc20_private"
  }
}

# VPC PEERING
resource "aws_vpc_peering_connection" "vpc_peering" {
  peer_vpc_id = aws_vpc.vpc10.id
  vpc_id      = aws_vpc.vpc20.id
  auto_accept = true

  tags = {
    "Name" = "vpc_peering"
  }
}

# ELASTIC IP
resource "aws_eip" "elastic_ip_pub_10" {
  vpc = true
}

resource "aws_eip" "elastic_ip_pub_20" {
  vpc = true
}

# NAT GATEWAY
resource "aws_nat_gateway" "ngw_vpc10" {
  allocation_id = aws_eip.elastic_ip_pub_10.id
  subnet_id     = aws_subnet.sn_vpc10_public.id
  depends_on    = [aws_internet_gateway.igw_vpc10]

  tags = {
    "Name" = "ngw_vpc10"
  }
}

resource "aws_nat_gateway" "ngw_vpc20" {
  allocation_id = aws_eip.elastic_ip_pub_20.id
  subnet_id     = aws_subnet.sn_vpc20_public.id
  depends_on    = [aws_internet_gateway.igw_vpc20]

  tags = {
    "Name" = "ngw_vpc20"
  }
}

# ROUTE TABLE
resource "aws_route_table" "rt_vpc10_public" {
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
    "Name" = "rt_vpc10_public"
  }
}

resource "aws_route_table" "rt_vpc10_private" {
  vpc_id = aws_vpc.vpc10.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw_vpc10.id
  }

  route {
    cidr_block = "20.0.0.0/16"
    gateway_id = aws_vpc_peering_connection.vpc_peering.id
  }

  tags = {
    "Name" = "rt_vpc10_private"
  }
}

resource "aws_route_table" "rt_vpc20_public" {
  vpc_id = aws_vpc.vpc20.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_vpc20.id
  }

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = aws_vpc_peering_connection.vpc_peering.id
  }

  tags = {
    "Name" = "rt_vpc20_public"
  }
}

resource "aws_route_table" "rt_vpc20_private" {
  vpc_id = aws_vpc.vpc20.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw_vpc20.id
  }

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = aws_vpc_peering_connection.vpc_peering.id
  }

  tags = {
    "Name" = "rt_vpc20_private"
  }
}

# SUBNET ASSOCIATION
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.sn_vpc10_public.id
  route_table_id = aws_route_table.rt_vpc10_public.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.sn_vpc10_private.id
  route_table_id = aws_route_table.rt_vpc10_private.id
}

resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.sn_vpc20_public.id
  route_table_id = aws_route_table.rt_vpc20_public.id
}

resource "aws_route_table_association" "d" {
  subnet_id      = aws_subnet.sn_vpc20_private.id
  route_table_id = aws_route_table.rt_vpc20_private.id
}

# SECURITY GROUP

# SG PÚBLICO VPC10
resource "aws_security_group" "sg_vpc10_public" {
  name        = "SG Pub VPC10"
  description = "SG para a rede publica"
  vpc_id      = aws_vpc.vpc10.id

  egress {
    description = "All to all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "All from 10.0.0.0/16 and 20.0.0.0/16"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16", "20.0.0.0/16"]
  }

  ingress {
    description = "Liberando a porta 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Liberando a porta 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Liberando a porta 3389"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "sg_vpc10_public"
  }
}

# SG PRIVADO VPC10
resource "aws_security_group" "sg_vpc10_private" {
  name        = "SG Private VPC10"
  description = "SG para rede privada"
  vpc_id      = aws_vpc.vpc10.id

  egress {
    description = "All to all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "All from 10.0.0.0/16 and 20.0.0.0/16"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16", "20.0.0.0/16"]
  }

  tags = {
    "Name" = "sg_vpc10_private"
  }
}

# SG PÚBLICO VPC20
resource "aws_security_group" "sg_vpc20_public" {
  name        = "SG Pub VPC20"
  description = "SG para a rede publica"
  vpc_id      = aws_vpc.vpc20.id

  egress {
    description = "All to all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "All from 10.0.0.0/16 and 20.0.0.0/16"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16", "20.0.0.0/16"]
  }

  ingress {
    description = "Liberando a porta 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Liberando a porta 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Liberando a porta 3389"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "sg_vpc20_public"
  }
}

# SG PRIVADO VPC20
resource "aws_security_group" "sg_vpc20_private" {
  name        = "SG Private VPC20"
  description = "SG para rede privada"
  vpc_id      = aws_vpc.vpc20.id

  egress {
    description = "All to all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "All from 10.0.0.0/16 and 20.0.0.0/16"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16", "20.0.0.0/16"]
  }

  tags = {
    "Name" = "sg_vpc20_private"
  }
}

# EC2 NAGIOS
resource "aws_instance" "nagios" {
  ami                    = "ami-087c17d1fe0178315"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.sn_vpc10_public.id
  vpc_security_group_ids = [aws_security_group.sg_vpc10_public.id]
  user_data              = <<-EOF
   #!/bin/bash
        # Nagios Core Install Instructions
        # https://support.nagios.com/kb/article/nagios-core-installing-nagios-core-from-source-96.html
        yum update -y
        setenforce 0
        cd /tmp
        yum install -y gcc glibc glibc-common make gettext automake autoconf wget openssl-devel net-snmp net-snmp-utils epel-release
        yum install -y perl-Net-SNMP
        yum install -y unzip httpd php gd gd-devel perl postfix
        cd /tmp
        wget -O nagioscore.tar.gz https://github.com/NagiosEnterprises/nagioscore/archive/nagios-4.4.5.tar.gz
        tar xzf nagioscore.tar.gz
        cd /tmp/nagioscore-nagios-4.4.5/
        ./configure
        make all
        make install-groups-users
        usermod -a -G nagios apache
        make install
        make install-daemoninit
        systemctl enable httpd.service
        make install-commandmode
        make install-config
        make install-webconf
        iptables -I INPUT -p tcp --destination-port 80 -j ACCEPT
        ip6tables -I INPUT -p tcp --destination-port 80 -j ACCEPT
        htpasswd -b -c /usr/local/nagios/etc/htpasswd.users nagiosadmin nagiosadmin
        service httpd start
        service nagios start
        cd /tmp
        wget --no-check-certificate -O nagios-plugins.tar.gz https://github.com/nagios-plugins/nagios-plugins/archive/release-2.2.1.tar.gz
        tar zxf nagios-plugins.tar.gz
        cd /tmp/nagios-plugins-release-2.2.1/
        ./tools/setup
        ./configure
        make
        make install
        service nagios restart
        echo done > /tmp/nagioscore.done
	EOF

  tags = {
    "Name" = "nagios"
  }
}

# EC2 node_a
resource "aws_instance" "node_a" {
  ami                    = "ami-087c17d1fe0178315"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.sn_vpc10_public.id
  vpc_security_group_ids = [aws_security_group.sg_vpc10_public.id]
  user_data              = <<-EOF
  #!/bin/bash
        # NCPA Agent Install instructions
        # https://assets.nagios.com/downloads/ncpa/docs/Installing-NCPA.pdf
        yum update -y
        rpm -Uvh https://assets.nagios.com/downloads/ncpa/ncpa-latest.el7.x86_64.rpm
        systemctl restart ncpa_listener.service
        echo done > /tmp/ncpa-agent.done
        # SNMP Agent install instructions
        # https://www.site24x7.com/help/admin/adding-a-monitor/configuring-snmp-linux.html
        yum update -y
        yum install net-snmp -y
        echo "rocommunity public" >> /etc/snmp/snmpd.conf
        service snmpd restart
        echo done > /tmp/snmp-agent.done
	EOF

  tags = {
    "Name" = "node_a"
  }
}

# EC2 node_b
resource "aws_instance" "node_b" {
  ami                    = "ami-087c17d1fe0178315"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.sn_vpc20_public.id
  vpc_security_group_ids = [aws_security_group.sg_vpc20_public.id]
  user_data              = <<-EOF
  #!/bin/bash
        # NCPA Agent Install instructions
        # https://assets.nagios.com/downloads/ncpa/docs/Installing-NCPA.pdf
        yum update -y
        rpm -Uvh https://assets.nagios.com/downloads/ncpa/ncpa-latest.el7.x86_64.rpm
        systemctl restart ncpa_listener.service
        echo done > /tmp/ncpa-agent.done
        # SNMP Agent install instructions
        # https://www.site24x7.com/help/admin/adding-a-monitor/configuring-snmp-linux.html
        yum update -y
        yum install net-snmp -y
        echo "rocommunity public" >> /etc/snmp/snmpd.conf
        service snmpd restart
        echo done > /tmp/snmp-agent.done
	EOF

  tags = {
    "Name" = "node_b"
  }
}

# EC2 node_c
resource "aws_instance" "node_c" {
  ami                    = "ami-087c17d1fe0178315"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.sn_vpc10_private.id
  vpc_security_group_ids = [aws_security_group.sg_vpc10_private.id]
  user_data              = <<-EOF
  #!/bin/bash
        # NCPA Agent Install instructions
        # https://assets.nagios.com/downloads/ncpa/docs/Installing-NCPA.pdf
        yum update -y
        rpm -Uvh https://assets.nagios.com/downloads/ncpa/ncpa-latest.el7.x86_64.rpm
        systemctl restart ncpa_listener.service
        echo done > /tmp/ncpa-agent.done
        # SNMP Agent install instructions
        # https://www.site24x7.com/help/admin/adding-a-monitor/configuring-snmp-linux.html
        yum update -y
        yum install net-snmp -y
        echo "rocommunity public" >> /etc/snmp/snmpd.conf
        service snmpd restart
        echo done > /tmp/snmp-agent.done
	EOF

  tags = {
    "Name" = "node_c"
  }
}

# EC2 node_d
resource "aws_instance" "node_d" {
  ami                    = "ami-087c17d1fe0178315"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.sn_vpc20_private.id
  vpc_security_group_ids = [aws_security_group.sg_vpc20_private.id]
  user_data              = <<-EOF
  #!/bin/bash
        # NCPA Agent Install instructions
        # https://assets.nagios.com/downloads/ncpa/docs/Installing-NCPA.pdf
        yum update -y
        rpm -Uvh https://assets.nagios.com/downloads/ncpa/ncpa-latest.el7.x86_64.rpm
        systemctl restart ncpa_listener.service
        echo done > /tmp/ncpa-agent.done
        # SNMP Agent install instructions
        # https://www.site24x7.com/help/admin/adding-a-monitor/configuring-snmp-linux.html
        yum update -y
        yum install net-snmp -y
        echo "rocommunity public" >> /etc/snmp/snmpd.conf
        service snmpd restart
        echo done > /tmp/snmp-agent.done
	EOF

  tags = {
    "Name" = "node_d"
  }
}

*/



