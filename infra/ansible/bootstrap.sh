#!/bin/bash
# EC2 user-data bootstrap: installs everything needed to run this stack.
# Runs once as root on first boot (cloud-init). Idempotent-ish; safe to
# re-run manually via SSH if you need to.
set -euxo pipefail

exec > >(tee /var/log/lab-bootstrap.log) 2>&1
echo "=== DevOps lab bootstrap starting: $(date) ==="

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y

# --- Docker ---
apt-get install -y ca-certificates curl gnupg git jq unzip
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

usermod -aG docker ubuntu

# --- kubectl ---
KUBECTL_VERSION="$(curl -L -s https://dl.k8s.io/release/stable.txt)"
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm -f kubectl

# --- Minikube (driver=docker, matches the free-tier RAM-constrained plan) ---
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install -o root -g root -m 0755 minikube-linux-amd64 /usr/local/bin/minikube
rm -f minikube-linux-amd64

# --- swap file: t3.micro has 1GB RAM, this gives Minikube/Docker breathing room ---
if [ ! -f /swapfile ]; then
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo "/swapfile none swap sw 0 0" >> /etc/fstab
fi

# --- clone the repo (set via cloud-init var or do it manually post-boot) ---
mkdir -p /opt/devops-lab
chown ubuntu:ubuntu /opt/devops-lab

echo "=== Bootstrap complete: $(date) ==="
echo "Next steps (as ubuntu user):"
echo "  1. git clone <your-repo-url> /opt/devops-lab && cd /opt/devops-lab"
echo "  2. docker compose up -d --build          # full stack demo"
echo "  3. minikube start --driver=docker --memory=1800mb --cpus=1   # K8s deliverable"
echo "  4. kubectl apply -f k8s/base/"
