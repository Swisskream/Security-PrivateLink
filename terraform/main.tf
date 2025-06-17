provider "aws" {
    region = var.aws_region
}

# Service VPC
resource "aws_vpc" "service_vpc" {
    cidr_block = var.service_vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support = true
    tags = {
        Name = "Service-VPC"
    }
}

resource "aws_subnet" "service_private_subnet" {
    vpc_id = aws_vpc.service_vpc.id
    cidr_block = var.service_private_subnet_cidr
    availability_zone = "${var.aws_region}a"
    tags = {
        Name = "Service-Private-Subnet"
    }
}

#Consumer VPC
resource "aws_vpc" "consumer_vpc" {
    cidr_block = var.consumer_vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support = true
    tags = {
        Name = "Consumer-VPC"
    }
}

resource "aws_subnet" "consumer_public_subnet" {
    vpc_id = aws_vpc.consumer_vpc.id
    cidr_block = var.consumer_public_subnet_cidr
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
    subnet_id = aws_subnet.consumer_public_subnet.id
    route_table_id = aws_route_table.consumer_public_rt.id
}

#Security Groups
resource "aws_security_group" "api_sg" {
    vpc_id = aws_vpc.service_vpc.id
    name = "api-sg"
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = [var.service_vpc_cidr]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "API-SG"
    }
}

resource "aws_security_group" "consumer_sg" {
    vpc_id = aws_vpc.consumer_vpc.id
    name "consumer-sg"
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # Restrict to your IP in production <-------------------
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "Consumer-SG"
    }
}

resource "aws_security_group" "endpoint_sg" {
    vpc_id = aws_vpc.consumer_vpc.id
    name = "endpoint-sg"
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = [var.consumer_vpc_cidr]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "Endpoint-SG"
    }
}

