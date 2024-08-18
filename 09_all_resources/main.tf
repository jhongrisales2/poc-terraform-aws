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


# ----------------------------------------------------------------------------------------------------------------------
# 03_EC2 - Elastic Cloud Computing
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_launch_template" "asg_template_poc_lendfront" {
  name_prefix            = "${var.prefix_name}${var.asg_name_prefix_template}"
  image_id               = var.ec2_ami_amzlinux
  instance_type          = var.ec2_app_instance_type
  key_name               = ""
  user_data              = filebase64("${path.module}/user-data/script-launch.sh")
  vpc_security_group_ids = [aws_security_group.sg_ec2_app_lendfront.id]
}

resource "aws_autoscaling_group" "asg_app_poc_lendfront" {
  #availability_zones = ["us-west-2a"]
  vpc_zone_identifier = [aws_subnet.subnet_public_az1_lendfront.id, aws_subnet.subnet_public_az2_lendfront.id]
  desired_capacity    = 2
  max_size            = 2
  min_size            = 1

  launch_template {
    id      = aws_launch_template.asg_template_poc_lendfront.id
    version = aws_launch_template.asg_template_poc_lendfront.latest_version
  }

  tag {
    key                 = "Name"
    value               = "${var.prefix_name}ec2-asg-poc-lendfront"
    propagate_at_launch = true
  }
}

resource "aws_instance" "ec2_poc_lendfront" {
  ami                  = var.ec2_ami_amzlinux
  instance_type        = var.ec2_app_instance_type
  subnet_id            = aws_subnet.subnet_public_az1_lendfront.id
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_instance_profile.name
  key_name             = ""

  tags = {
    Name = "${var.prefix_name}${var.ec2_server_name}"
  }

  user_data = <<-EOF
    #!/bin/bash
    yum install -y amazon-ssm-agent
    systemctl start amazon-ssm-agent
  EOF
}


# ----------------------------------------------------------------------------------------------------------------------
# 04_SG - AWS Security Group (HTTP: 80, 8080)
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "sg_alb_poc_lendfront" {
  name        = "${var.prefix_name}${var.sg_alb_name_poc}"
  description = "ALB - Security Group"
  vpc_id      = aws_vpc.vpc_poc_lendfront.id

  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Enables HTTP access to port 80"
  }

  ingress {
    from_port   = "8080"
    to_port     = "8080"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Enables HTTP access to port 8080"
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix_name}${var.sg_alb_name_poc}"
  }
}

resource "aws_security_group" "sg_ec2_app_lendfront" {
  name        = "${var.prefix_name}${var.sg_ec2_name_poc}"
  description = "EC2 APP - Security Group"
  vpc_id      = aws_vpc.vpc_poc_lendfront.id

  ingress {
    from_port       = "80"
    to_port         = "80"
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_alb_poc_lendfront.id]
    description     = "Enables HTTP access to port 80"
  }

  ingress {
    from_port       = "8080"
    to_port         = "8080"
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_alb_poc_lendfront.id]
    description     = "Enables HTTP access to port 8080"
  }

  # EGRESS RULES
  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix_name}${var.sg_alb_name_poc}"
  }
}


# ----------------------------------------------------------------------------------------------------------------------
# 04_ELB - Application Load Balancer
# ----------------------------------------------------------------------------------------------------------------------

resource "aws_lb" "alb_poc_lendfront" {
  name               = "${var.prefix_name}${var.alb_name_poc_lendfront}"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_alb_poc_lendfront.id]
  subnets            = [aws_subnet.subnet_public_az1_lendfront.id, aws_subnet.subnet_public_az2_lendfront.id]

  enable_deletion_protection = false

  tags = {
    Name = "${var.prefix_name}${var.alb_name_poc_lendfront}"
  }
  depends_on = [aws_autoscaling_group.asg_app_poc_lendfront]
}

resource "aws_lb_target_group" "lb_target_group_lendfront" {
  name        = "${var.prefix_name}${var.lb_tg_name}"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.vpc_poc_lendfront.id

  depends_on = [aws_lb.alb_poc_lendfront]
}

resource "aws_lb_listener" "front_end_80" {
  load_balancer_arn = aws_lb.alb_poc_lendfront.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group_lendfront.arn
  }
  depends_on = [aws_lb_target_group.lb_target_group_lendfront]
}

resource "aws_lb_listener" "front_end_8080" {
  load_balancer_arn = aws_lb.alb_poc_lendfront.arn
  port              = 8080
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group_lendfront.arn
  }
  depends_on = [aws_lb_target_group.lb_target_group_lendfront]
}

resource "aws_autoscaling_attachment" "asg_attachment_lb" {
  autoscaling_group_name = aws_autoscaling_group.asg_app_poc_lendfront.name
  lb_target_group_arn    = aws_lb_target_group.lb_target_group_lendfront.arn
  depends_on             = [aws_autoscaling_group.asg_app_poc_lendfront, aws_lb_target_group.lb_target_group_lendfront]
}

