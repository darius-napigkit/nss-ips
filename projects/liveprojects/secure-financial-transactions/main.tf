# --- Common Data: EC2 Trust Policy Document ---
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# ------------------------------------------------
# MODULE CALL TO GENERATE STANDARD TAGS
# ------------------------------------------------
module "standard_tags" {
  source = "git::https://github.com/darius-napigkit/nss-ips-common.git//terraform/modules/aws/tagging-standard?ref=develop" # Pointing to a GitHub repo and branch

  environment = "Development"
  project     = "Manning"

  # Custom tags specific to this root configuration
  additional_tags = {
    Name       = "liveproject"
    Cluster    = "None"
    Creator    = "Terraform"
    Expires    = "2025-12-01T00:00:00+00:00"
    Service    = "Compliance"
    Management = "dnapigkit@gmail.com"
    Freetext   = "Account for liveproject: Mastering Compliance with Ansible Terraform and OpenSCAP"
  }
}

# ------------------------------------------------
# LiveProject Role for a power user (FULL ACCESS USER CREATED)
# ------------------------------------------------
module "liveproject_role" {
  source = "git::https://github.com/darius-napigkit/nss-ips-common.git//terraform/modules/aws/iam-role?ref=develop" # Pointing to a GitHub repo and branch

  role_name          = "LiveProject-Role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  # Pass the tags output from the tagging module
  tags = module.standard_tags.tags

  # Attach multiple policies
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]

  # --- New User Creation Configuration (Enabled) ---
  create_iam_user              = true
  iam_user_name                = "liveproject"

  # --- NEW ACCESS CONFIGURATION ---
  create_programmatic_access   = true
  create_console_access        = true
  assign_power_user_policy     = true # Assigns PowerUserAccess policy
}
