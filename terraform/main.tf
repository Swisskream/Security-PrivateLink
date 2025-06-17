provider "aws" {
  region = var.aws_region
}

# Service VPC
resource "aws_vpc" "service_vpc" {
  cidr_block           = var.service_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "Service-VPC"
  }
}

resource "aws_subnet" "service_private_subnet" {
  vpc_id            = aws_vpc.service_vpc.id
  cidr_block        = var.service_private_subnet_cidr
  availability_zone = "${var.aws_region}a"
  tags = {
    Name = "Service-Private-Subnet"
  }
}

#Consumer VPC
resource "aws_vpc" "consumer_vpc" {
  cidr_block           = var.consumer_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "Consumer-VPC"
  }
}

resource "aws_subnet" "consumer_public_subnet" {
  vpc_id            = aws_vpc.consumer_vpc.id
  cidr_block        = var.consumer_public_subnet_cidr
  availability_zone = "${var.aws_region}a"
  tags = {
    Name = "Consumer-Public-Subnet"
  }
}

# Internet Gateway for Consumer VPC (for testing)
resource "aws_internet_gateway" "consumer_igw" {
  vpc_id = aws_vpc.consumer_vpc.id
  tags = {
    Name = "Consumer-IGW"
  }
}

# Route Table for Consumer Public Subnet
resource "aws_route_table" "consumer_public_rt" {
  vpc_id = aws_vpc.consumer_vpc.id
  route = {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.consumer_igw.id
  }
  tags = {
    Name = "Consumer-Public-RT"
  }
}

resource "aws_route_table_association" "consumer_public_rt_assoc" {
  subnet_id      = aws_subnet.consumer_public_subnet.id
  route_table_id = aws_route_table.consumer_public_rt.id
}

#Security Groups
resource "aws_security_group" "api_sg" {
  vpc_id = aws_vpc.service_vpc.id
  name   = "api-sg"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.service_vpc_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "API-SG"
  }
}

resource "aws_security_group" "consumer_sg" {
  vpc_id = aws_vpc.consumer_vpc.id
  name   = "consumer-sg"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict to your IP in production <-------------------
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Consumer-SG"
  }
}

resource "aws_security_group" "endpoint_sg" {
  vpc_id = aws_vpc.consumer_vpc.id
  name   = "endpoint-sg"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.consumer_vpc_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Endpoint-SG"
  }
}

# IAM Role for EC2 Instances (for SSM access)
resource "aws_iam_role" "ec2_role" {
  name = "EC2-SSM-Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "EC2-SSM-Profile"
  role = aws_iam_role.ec2_role.name
}

# API EC2 Instance
resource "aws_instance" "api_server" {
  ami                    = "ami-0cbad6815f3a09a6d"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.service_private_subnet.id
  vpc_security_group_ids = [aws_security_group.api_sg.id]
  user_data              = file("user_data_api.sh")
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  tags = {
    Name = "API-Server"
  }
}

#Consumer EC2 Instance
resource "aws_instance" "consumer_app" {
  ami                    = "ami-0cbad6815f3a09a6d"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.consumer_public_subnet.id
  vpc_security_group_ids = [aws_security_group.consumer_sg.id]
  user_data              = file("user_data_consumer.sh")
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  tags = {
    Name = "Consumer-App"
  }
}

#Network Load Balancer
resource "aws_lb" "nlb" {
  name               = "privatelink-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = [aws_subnet.service_private_subnet.id]
  tags = {
    Name = "PrivateLink-NLB"
  }
}

resource "aws_lb_target_group" "api_target" {
  name     = "api-target"
  port     = 80
  protocol = "TCP"
  vpc_id   = aws_vpc.service_vpc.id
  health_check {
    protocol = "TCP"
  }
}

resouce "aws_lb_target_group_attachment" "api_target_attachment" {
  target_group_arn = aws_lb_target_group.api_target.arn
  target_id        = aws_instance.api_server.id
  port             = 80
}

resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_target.arn
  }
}

# VPC Endpoint Service (PrivateLink)
resource "aws_vpc_endpoint_service" "api_service" {
  acceptance_required        = true
  network_load_balancer_arns = [aws_lb.nlb.arn]
  tags = {
    Name = "PrivateLink-API-Service"
  }
}

#Allow Consumer VPC to access the Endpoint Service
resource "aws_vpc_endpoint_service_allowed_principal" "allow_consumer" {
  vpc_endpoint_service_id = aws_vpc_endpoint_service.api_service.id
  principal_arn           = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
}

data "aws_caller_identity" "current" {}

# VPC Endpoint in Consumer VPC
resource "aws_vpc_endpoint" "consumer_endpoint" {
  vpc_id             = aws_vpc.consumer_vpc.id
  service_name       = aws_vpc_endpoint_service.api_service.service_name
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.consumer_public_subnet.id]
  security_group_ids = [aws_security_group.endpoint_sg.id]
  tags = {
    Name = "Consumer-Endpoint"
  }
}