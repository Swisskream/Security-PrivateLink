output "api_instance_id" {
    description = "ID of the API server EC2 instance"
    value = aws_instance.api_server.id
}

output "consumer_instance_id" {
    description = "ID of the Consumer EC2 instance"
    value = "aws_instance.consumer_app.id"
}

output "nlb_dns_name" {
    description = "DNS name of the Network Load Balancer"
    value = "aws_lb.nlb.dns_name"
}

output "endpoint_dns_name" {
    description = "DNS name of the VPC endpoint"
    value = "aws_vpc_endpoint.consumer_endpoint.dns_entry[0].dns_name"
}