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
