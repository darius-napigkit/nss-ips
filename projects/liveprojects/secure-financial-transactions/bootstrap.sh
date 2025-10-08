#!/usr/bin/env bash
set -euo pipefail

# Elevate to root and run package setup
sudo su - <<'ROOT'
set -e
dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
# Ensure config-manager is available
dnf -y install dnf-plugins-core
dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
dnf -y install ansible terraform git
ROOT

# Back as ec2-user: create SSH key pair with empty passphrase if not present
mkdir -p ~/.ssh
chmod 700 ~/.ssh
if [ ! -f ~/.ssh/id_rsa ]; then
  ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" -q
fi
