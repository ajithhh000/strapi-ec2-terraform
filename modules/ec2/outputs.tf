output "public_ip" {
  description = "Public IP of the instance"
  value       = aws_instance.strapi.public_ip
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.strapi.id
}

output "private_key" {
  description = "Private SSH key"
  value       = tls_private_key.ssh.private_key_pem
  sensitive   = true
}

output "vpc_id" {
  description = "Default VPC ID used"
  value       = data.aws_vpc.default.id
}
