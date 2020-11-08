# Provider Section

provider "aws" {
  access_key = "ACCESS_KEY_HERE"
  secret_key = "SECRET_KEY_HERE"
  region     = "ap-southeast-1"
}

# VPC section

resource "aws_vpc" "main_vpc" {
  cidr_block       = "${var.vpc_cidr}"
  instance_tenancy = "${var.vpc_tenency}"

  tags {
    Name  = "main-vpc"
  }
}

#Subnet section

resource "aws_subnet" "webservers" {
  count                   = "${var.public_subnets_count}"
  vpc_id                  = "${aws_vpc.main_vpc.id}"
  cidr_block              = "${var.cidr_webservers[count.index]}"
  availability_zone       = "${data.aws_availability_zones.azs.names[count.index]}"
  map_public_ip_on_launch = true
  tags {
    Name = "Webserver-${count.index + 1}"
  }
}

# Ec2 instance section

resource "aws_instance" "webservers" {
  count                  = "${var.web_servers_count}"
  ami                    = "${lookup(var.web_ami,var.region)}"
  instance_type          = "${var.ec2_instance_type}"
  subnet_id              = "${element(aws_subnet.webservers.*.id,count.index)}"
  vpc_security_group_ids = ["${aws_security_group.web_sg.id}"]
  key_name               = "hari"
  user_data = "${file("./scripts/setup_apache.sh")}"

  tags {
    Name = "Webserver-${count.index+1}"
  }
}


# Security Group Section

resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Allow http traffic"
  vpc_id      = "${aws_vpc.main_vpc.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


#variable section

variable "region" {
  type        = "string"
  description = "Choose the region"
  default     = "ap-southeast-1"
}

variable "web_ami" {
  type = "map"

  default = {
    ap-southsouth-1 = "ami-015a6758451df3cb9"
  }
}


variable "subnet_cidr" {
  type    = "list"
  default = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]
}

variable "ec2_instance_type" {
  default = "t2.micro"
}

variable "ec2_keyname" {
  default = "ec2key"
}

variable "vpc_cidr" {
  default = "192.50.0.0/16"
}

variable "vpc_tenency" {
  default = "default"
}

variable "cidr_webservers" {
  type    = "list"
  default = ["192.50.1.0/24", "192.50.2.0/24"]
}

# Declare the data source
data "aws_availability_zones" "azs" {}

variable "public_subnets_count" {
  default = "2"
}

variable "web_servers_count" {
  default = "2"
}

