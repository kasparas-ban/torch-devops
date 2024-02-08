variable "region" {
  description = "Selected AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "personal_ip" {
  description = "The personal IP address to allow SSH access from to EC2 instance"
  type        = string
}

variable "vpc_ipv4_cidr" {
  description = "Value of the IPv4 CIDR range for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  description = "Value of the name for the VPC"
  type        = string
  default     = "torch_vpc"
}

variable "subnet_name" {
  description = "Name of the subnet for the VPC"
  type        = string
  default     = "torch_pub_subnet"
}

variable "igw_name" {
  description = "Name of the Internet Gateway for the VPC"
  type        = string
  default     = "torch_igw"
}

variable "pub_rt_name" {
  description = "Name of the public Route Table for the VPC"
  type        = string
  default     = "torch_rt"
}

variable "ec2_ami" {
  description = "Value of the AMI ID for the EC2 instance"
  type        = string
  default     = "ami-03614aa887519d781"
}

variable "ec2_name" {
  description = "Value of the Name for the EC2 instance"
  type        = string
  default     = "torch_server"
}