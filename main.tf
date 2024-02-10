provider "aws" {
  region = var.region
}

# Availability Zones
data "aws_availability_zones" "available" {
  state = "available"
}

// Ubuntu 20.04 server AMI
data "aws_ami" "ubuntu" {
  most_recent = "true"

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

# VPC
resource "aws_vpc" "torch_vpc" {
  cidr_block                       = var.vpc_ipv4_cidr
  assign_generated_ipv6_cidr_block = true

  tags = {
    Name = "torch_vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "torch_igw" {
  vpc_id = aws_vpc.torch_vpc.id

  tags = {
    Name = "torch_igw"
  }
}

# Public Subnet
resource "aws_subnet" "torch_public_subnet" {
  vpc_id            = aws_vpc.torch_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.torch_vpc.cidr_block, 8, 1)
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "torch_public_subnet"
  }
}

# Private Subnet
resource "aws_subnet" "torch_private_subnet" {
  count             = 2
  vpc_id            = aws_vpc.torch_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.torch_vpc.cidr_block, 8, 2 + count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "torch_private_subnet_${count.index}"
  }
}

# Public Route Table
resource "aws_route_table" "torch_public_rt" {
  vpc_id = aws_vpc.torch_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.torch_igw.id
  }

  tags = {
    Name = "torch_public_rt"
  }
}

# Associates public route table with a public subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.torch_public_subnet.id
  route_table_id = aws_route_table.torch_public_rt.id
}

# Private Route Table
resource "aws_route_table" "torch_private_rt" {
  vpc_id = aws_vpc.torch_vpc.id

  tags = {
    Name = "torch_private_rt"
  }
}

# Associates private route table with a private subnet
resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.torch_private_subnet[count.index].id
  route_table_id = aws_route_table.torch_private_rt.id
}

# Security Group for EC2
resource "aws_security_group" "torch_ec2_sg" {
  name        = "torch_ec2_sg"
  description = "Security group for RC2 instance (torch server)"
  vpc_id      = aws_vpc.torch_vpc.id

  ingress {
    description = "Allow all traffic through HTTP"
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH from personal computer"
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = [var.personal_ip]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "torch_ec2_sg"
  }
}

# Security Group for RDS
resource "aws_security_group" "torch_rds_sg" {
  name        = "torch_rds_sg"
  description = "Security group for RDS instance (torch database)"
  vpc_id      = aws_vpc.torch_vpc.id

  ingress {
    description     = "Allow MySQL traffic only from the EC2 security group"
    from_port       = "3306"
    to_port         = "3306"
    protocol        = "tcp"
    security_groups = [aws_security_group.torch_ec2_sg.id]
  }

  tags = {
    Name = "torch_rds_sg"
  }
}

# Subnet Group for RDS
resource "aws_db_subnet_group" "torch_rds_subnet_group" {
  name        = "torch_rds_subnet_group"
  description = "RDS subnet group"
  subnet_ids  = [for subnet in aws_subnet.torch_private_subnet : subnet.id]
}

# RDS database
resource "aws_db_instance" "torch_database" {
  db_name                = "torch_db"
  identifier             = "torch-db"
  engine                 = "mysql"
  engine_version         = "8.0.35"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.torch_rds_subnet_group.id
  vpc_security_group_ids = [aws_security_group.torch_rds_sg.id]
  skip_final_snapshot    = true
}

# EC2 key pair
resource "aws_key_pair" "torch_server_keypair" {
  key_name   = "torch_server_keypair"
  public_key = file("./torch-server-keypair.pub")
}

# EC2
resource "aws_instance" "torch_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  key_name                    = aws_key_pair.torch_server_keypair.key_name
  subnet_id                   = aws_subnet.torch_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.torch_ec2_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update && sudo apt upgrade -y
              wget https://go.dev/dl/go1.22.0.linux-amd64.tar.gz && sudo tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz
              sudo sh -c 'echo "PATH=$PATH:/usr/local/go/bin" >> /etc/environment'
              EOF

  tags = {
    Name = "torch_server"
  }
}

# output "ec2instance" {
#   value = aws_instance.project-iac.public_ip
# }
