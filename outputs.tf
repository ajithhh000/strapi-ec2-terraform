output "instance_public_ip" {
  description = "Public IP of EC2 instance"
  value       = module.ec2.public_ip
}


output "private_key" {
  description = "Private key for SSH"
  value       = module.ec2.private_key
  sensitive   = true
}
