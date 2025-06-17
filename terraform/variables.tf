var "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-west-1"
}

var "service_vpc_cidr" {
  description = "CIDR block for Service VPC"
  type        = string
  default     = "10.0.0.0/16"
}

var "consumer_vpc_cidr" {
  description = "CIDR block for Consumer VPC"
  type        = string
  default     = "10.1.0.0/16"
}

var "service_private_subnet_cidr" {
  description = "CIDR for Service VPC private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

var "consumer_public_subnet_cidr" {
  description = "CIDR for Consumer VPC public subnet"
  type        = string
  default     = "10.1.1.0/24"
}