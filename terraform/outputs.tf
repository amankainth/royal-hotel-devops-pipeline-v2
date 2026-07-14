output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "Public Subnet ID"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.dev_instance.id
}

output "dev_instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.dev_instance.id
}

output "dev_instance_public_ip" {
  description = "Public IP of dev server"
  value       = aws_instance.dev_instance.public_ip
}

output "dev_instance_private_ip" {
  description = "Private IP of dev server"
  value       = aws_instance.dev_instance.private_ip
}

output "ssh_key_path" {
  description = "Path to SSH private key on Jenkins"
  value       = local_sensitive_file.dev_key_pem.filename
}

output "ssh_command" {
  description = "Ready-to-use SSH command"
  value       = "ssh -i ${local_sensitive_file.dev_key_pem.filename} ec2-user@${aws_instance.dev_instance.public_ip}"
}

output "app_url" {
  description = "Application URL after deployment"
  value       = "http://${aws_instance.dev_instance.public_ip}"
}
