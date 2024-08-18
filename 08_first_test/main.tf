# 01_IAM resources

resource "aws_iam_role" "ec2_ssm_role" {
  name = var.iam_user_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_ssm_instance_profile" {
  name = var.name_ec2_instance_profile
  role = aws_iam_role.ec2_ssm_role.name
}


# 02_VPC resources

resource "aws_vpc" "vpc_poc_lendfront" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.prefix_name}${var.name_vpc}"
  }
}

resource "aws_subnet" "subnet_public_az1_lendfront" {
  vpc_id                  = aws_vpc.vpc_poc_lendfront.id
  cidr_block              = var.cidr_public_subnet_az1
  map_public_ip_on_launch = true
  availability_zone       = "us-west-2a"
  tags = {
    Name = "${var.prefix_name}${var.subnet_name_public_az1}"
  }
}

resource "aws_subnet" "subnet_public_az2_lendfront" {
  vpc_id                  = aws_vpc.vpc_poc_lendfront.id
  cidr_block              = var.cidr_public_subnet_az2
  map_public_ip_on_launch = true
  availability_zone       = "us-west-2b"
  tags = {
    Name = "${var.prefix_name}${var.subnet_name_public_az2}"
  }
}

resource "aws_internet_gateway" "igw_poc_lendfront" {
  vpc_id = aws_vpc.vpc_poc_lendfront.id
  tags = {
    Name = "${var.prefix_name}${var.name_igw}"
  }
}

resource "aws_route_table" "rt_public_poc_lendfront" {
  vpc_id = aws_vpc.vpc_poc_lendfront.id

  route {
    cidr_block = var.route_cidr_block
    gateway_id = aws_internet_gateway.igw_poc_lendfront.id
  }

  tags = {
    Name = "${var.prefix_name}${var.name_public_rt}"
  }
}

resource "aws_route_table_association" "assoc_public_az1_poc_rt" {
  subnet_id      = aws_subnet.subnet_public_az1_lendfront.id
  route_table_id = aws_route_table.rt_public_poc_lendfront.id
}

resource "aws_route_table_association" "assoc_public_az2_poc_rt" {
  subnet_id      = aws_subnet.subnet_public_az2_lendfront.id
  route_table_id = aws_route_table.rt_public_poc_lendfront.id
}


resource "aws_instance" "ec2_poc_lendfront" {
  ami                  = var.ec2_ami_amzlinux
  instance_type        = var.ec2_app_instance_type
  subnet_id            = aws_subnet.subnet_public_az1_lendfront.id
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_instance_profile.name
  key_name             = ""
  user_data              = filebase64("${path.module}/user-data/script-launch.sh")

  tags = {
    Name = "${var.prefix_name}${var.ec2_server_name}"
  }
}
