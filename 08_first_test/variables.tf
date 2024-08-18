# 01_IAM resources

variable "iam_user_name" {
  description = "The name for the iam user"
  type        = string
  default     = "azure-devops"
}

variable "name_ec2_instance_profile" {
  description = "The name for the ec2 instance profile"
  type        = string
  default     = "ec2-profile-poc-lendfront"
}


# 02_VPC resources

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.96.0.0/16"
}

variable "name_vpc" {
  description = "The name for the new main VPC"
  type        = string
  default     = "vpc-main-poc"
}

variable "cidr_public_subnet_az1" {
  description = "The CIDR block for the public subnets"
  type        = string
  default     = "10.96.0.0/24"
}

variable "cidr_public_subnet_az2" {
  description = "The CIDR block for the public subnets"
  type        = string
  default     = "10.96.1.0/24"
}

variable "subnet_name_public_az1" {
  description = "The name for the public subnet"
  type        = string
  default     = "subnet-public-az1-lendfront"
}

variable "subnet_name_public_az2" {
  description = "The name for the public subnet"
  type        = string
  default     = "subnet-public-az2-lendfront"
}

variable "name_igw" {
  description = "The name for the internet gateway"
  type        = string
  default     = "igw-poc-lendfront"
}

variable "route_cidr_block" {
  description = "The CIDR block for the route for rt"
  type        = string
  default     = "0.0.0.0/0"
}

variable "name_public_rt" {
  description = "The name for the public route table"
  type        = string
  default     = "rt-public-poc-lendfront"
}



variable "ec2_app_instance_type" {
  description = "Name to be used on ec2 application instance"
  type        = string
  default     = "t2.micro"
}

variable "ec2_server_name" {
  description = "Name to be used on ec2 application instance"
  type        = string
  default     = "ec2-main-application"
}

variable "ec2_ami_amzlinux" {
  description = "Id for AMI of Amazon Linux 2023 AMI (64-bit (x86), uefi-preferred)"
  type        = string
  default     = "ami-0a38c1c38a15fed74"
}



# GENERAL resources

variable "profile" {
  description = "The AWS profile to run infrastructure"
  type        = string
  default     = "048395857825_AdministratorAccess"
}

variable "aws_region" {
  description = "The AWS region where infrastructure will be run"
  type        = string
  default     = "us-east-1"
}

variable "prefix_name" {
  description = "prefix resources name"
  type        = string
  default     = "tf-"
}


