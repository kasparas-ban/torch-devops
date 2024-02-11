variable "region" {
  description = "Selected AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "db_username" {
  description = "Username for the RDS database"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Passowrd for the RDS database"
  type        = string
  sensitive   = true
}

variable "personal_ip" {
  description = "The personal IP address to allow SSH access from to EC2 instance"
  type        = string
}

variable "ssl_certificate_arn" {
  description = "ARN of the SSL certificate from the AWS Certificate Manager"
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

variable "ec2_name" {
  description = "Value of the Name for the EC2 instance"
  type        = string
  default     = "torch_server"
}
