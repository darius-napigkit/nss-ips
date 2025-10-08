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

# Discover the latest Red Hat Enterprise Linux 8 HVM AMI (x86_64) in the region
data "aws_ami" "rhel8" {
  most_recent = true
  owners      = ["309956199498"] # Red Hat, Inc.

  filter {
    name   = "name"
    values = ["RHEL-8.*_HVM-*x86_64*-Hourly2-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# Use the default VPC and one of its default (public) subnets
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# module "devnode_vpc" {
#   source = "git::https://github.com/darius-napigkit/nss-ips-common.git//terraform/modules/aws/vpc?ref=develop"
#
#   create_default_vpc = true
#   tags               = module.standard_tags.tags
# }

# Detect your current public IP for restricting SSH
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

locals {
  # Pick the first default subnet (default VPC subnets are public by default)
  public_subnet_id = tolist(data.aws_subnets.default_vpc_subnets.ids)[0]
  # public_subnet_id = tolist(module.devnode_vpc.default_subnet_ids)[0]

  # Convert fetched IP to CIDR /32
  my_ip_cidr = "${chomp(data.http.my_ip.response_body)}/32"
}

# module "devnode_sg" {
#   source = "git::https://github.com/darius-napigkit/nss-ips-common.git//terraform/modules/aws/ec2?ref=develop"
#
#   name = "development-node"
#   # add variable 'description' to common module
#   vpc_id = module.devnode_vpc.default_vpc_id
#
#   # add variable to common module for ingress description = "SSH from my IP"
#   allowed_port  = 22
#   allowed_cidrs = [local.my_ip_cidr]
#
#   # add variable to common module for egress description = "Allow all outbound"
#   egress_cidrs = ["0.0.0.0/0"]
#   # add variable to common module for egress ipv6_cidr_blocks = ["::/0"]
#
#   tags = module.standard_tags.tags
# }

# Security group allowing SSH only from your current IP
resource "aws_security_group" "development_node_sg" {
  name        = "development-node-sg"
  description = "Allow SSH only from my current IP"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.my_ip_cidr]
  }

  egress {
    description      = "Allow all outbound"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = module.standard_tags.tags
}

# Generate a new SSH key pair and register the public key with AWS
resource "tls_private_key" "development_node" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "development_node" {
  key_name   = "development-node-keypair"
  public_key = tls_private_key.development_node.public_key_openssh
  tags       = module.standard_tags.tags
}

# EC2 instance in the default VPC, public subnet, with public IP
resource "aws_instance" "development_node" {
  ami                    = data.aws_ami.rhel8.id
  instance_type          = "t2.micro"
  subnet_id              = local.public_subnet_id
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.development_node_sg.id
  ]

  key_name = aws_key_pair.development_node.key_name

  # Root volume: 10 GiB SSD
  root_block_device {
    volume_size           = 10
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = filebase64("${path.module}/bootstrap.sh")

  tags = module.standard_tags.tags
}
