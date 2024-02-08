provider "aws" {
  region = var.region
}

# VPC
resource "aws_vpc" "torch_vpc" {
  cidr_block                       = var.vpc_ipv4_cidr
  assign_generated_ipv6_cidr_block = true
}

# Subnet
resource "aws_subnet" "torch_subnet_a" {
  vpc_id                                         = aws_vpc.torch_vpc.id
  ipv6_native                                    = true
  ipv6_cidr_block                                = cidrsubnet(aws_vpc.torch_vpc.ipv6_cidr_block, 8, 1)
  assign_ipv6_address_on_creation                = true
  enable_resource_name_dns_aaaa_record_on_launch = true
  availability_zone                              = "${var.region}a"

  tags = {
    Name = var.subnet_name
  }
}

# Subnet
resource "aws_subnet" "torch_subnet_b" {
  vpc_id                                         = aws_vpc.torch_vpc.id
  ipv6_native                                    = true
  ipv6_cidr_block                                = cidrsubnet(aws_vpc.torch_vpc.ipv6_cidr_block, 8, 2)
  assign_ipv6_address_on_creation                = true
  enable_resource_name_dns_aaaa_record_on_launch = true
  availability_zone                              = "${var.region}b"

  tags = {
    Name = var.subnet_name
  }
}

# Internet Gateway
resource "aws_internet_gateway" "torch_igw" {
  vpc_id = aws_vpc.torch_vpc.id

  tags = {
    Name = var.igw_name
  }
}

# Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.torch_vpc.id

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.torch_igw.id
  }

  tags = {
    Name = var.pub_rt_name
  }
}

# Associates route table with subnet
resource "aws_route_table_association" "public_1_rt_assoc" {
  subnet_id      = aws_subnet.torch_subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_2_rt_assoc" {
  subnet_id      = aws_subnet.torch_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}

# Creates a new security group open to all HTTPS traffic
resource "aws_security_group" "torch_server_sg" {
  name        = "torch_server_sg"
  description = "Allow inbound HTTPS traffic for API server"
  vpc_id      = aws_vpc.torch_vpc.id

  # ingress {
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
  #   cidr_blocks = var.personal_ip != null ? [var.personal_ip] : []
  # }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }
}

# EC2 key pair
resource "aws_key_pair" "torch_server_keypair" {
  key_name   = "torch_server_keypair"
  public_key = file("./torch-server-keypair.pub")
}

# EC2
resource "aws_instance" "torch_server" {
  ami           = var.ec2_ami
  instance_type = "t3.nano"

  key_name               = aws_key_pair.torch_server_keypair.id
  subnet_id              = aws_subnet.torch_subnet_a.id
  vpc_security_group_ids = [aws_security_group.torch_server_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              EOF

  tags = {
    Name = "torch_server"
  }
}

# output "ec2instance" {
#   value = aws_instance.project-iac.public_ip
# }
