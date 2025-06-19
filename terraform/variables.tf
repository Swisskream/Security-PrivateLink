variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-west-1"
}

variable "service_vpc_cidr" {
  description = "CIDR block for Service VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "consumer_vpc_cidr" {
  description = "CIDR block for Consumer VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "service_private_subnet_cidr" {
  description = "CIDR for Service VPC private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "consumer_public_subnet_cidr" {
  description = "CIDR for Consumer VPC public subnet"
  type        = string
  default     = "10.1.1.0/24"
}