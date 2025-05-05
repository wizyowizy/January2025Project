# AWS Provider (make sure region is defined in a variable or hard-coded)
provider "aws" {
  region  = var.region
  profile = "default"
}

# Create a VPC
resource "aws_vpc" "prod_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "prod_vpc"
  }
}

# Create a Subnet
resource "aws_subnet" "prod_subnet1" {
  vpc_id     = aws_vpc.prod_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "prod_subnet1"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod_vpc.id

  tags = {
    Name = "IGW"
  }
}

# Create a Route Table
resource "aws_route_table" "prod_route" {
  vpc_id = aws_vpc.prod_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "prod_route"
  }
}

# Associate Subnet with Route Table
resource "aws_route_table_association" "subnet_association" {
  subnet_id      = aws_subnet.prod_subnet1.id
  route_table_id = aws_route_table.prod_route.id
}

# Create a Security Group
resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow webserver inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.prod_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP-ALT (8080)"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls_sg"
  }
}

# Get the latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Jenkins EC2 Instance
resource "aws_instance" "jenkins_instance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.prod_subnet1.id
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  key_name               = "wiseKP"
  associate_public_ip_address = true
  user_data              = file("install_jenkins.sh")

  tags = {
    Name = "Jenkins_Server"
  }
}

# Tomcat EC2 Instance
resource "aws_instance" "tomcat_instance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.prod_subnet1.id
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  key_name               = "wiseKP"
  associate_public_ip_address = true
  user_data              = file("install_tomcat.sh")

  tags = {
    Name = "Tomcat_Server"
  }
}

# Output Jenkins URL
output "jenkins_website_url" {
  description = "Jenkins Server URL"
  value       = "http://${aws_instance.jenkins_instance.public_ip}:8080"
}

# Output Tomcat URL
output "tomcat_website_url" {
  description = "Tomcat Server URL"
  value       = "http://${aws_instance.tomcat_instance.public_ip}:8080"
}
