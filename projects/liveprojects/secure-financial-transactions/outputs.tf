# Output the ARN of the created user for the liveproject role
output "liveproject_role_assumer_user_arn" {
  value       = module.liveproject_role.iam_user_arn
  description = "The ARN of the user created to assume the LiveProject Role."
}

# WARNING: Sensitive output for the LiveProject User
output "liveproject_user_credentials" {
  value = {
    access_key_id     = module.liveproject_role.access_key_id
    secret_access_key = module.liveproject_role.secret_access_key
    console_password  = module.liveproject_role.console_password
  }
  description = "Sensitive credentials for the liveproject-user. Save these immediately."
  sensitive   = true
}

output "development_node_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.development_node.public_ip
}

output "development_node_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.development_node.public_dns
}

# Key material outputs (marked sensitive). Retrieve with:
#   terraform output -raw development_node_private_key_pem > private_key.pem
#   chmod 600 private_key.pem
output "development_node_private_key_pem" {
  description = "Private key PEM for SSH (handle securely)"
  value       = tls_private_key.development_node.private_key_pem
  sensitive   = true
}

output "development_node_public_key_openssh" {
  description = "Public key in OpenSSH format"
  value       = tls_private_key.development_node.public_key_openssh
  sensitive   = true
}

output "development_node_key_pair_name" {
  description = "Registered AWS key pair name"
  value       = aws_key_pair.development_node.key_name
}
