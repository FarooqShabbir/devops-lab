variable "aws_region" {
  description = "AWS region. eu-north-1 (Stockholm) tends to have the cheapest on-demand rates if you ever exceed free tier."
  type        = string
  default     = "eu-north-1"
}

variable "instance_type" {
  description = <<-EOT
    EC2 instance type. t3.micro is covered by the AWS Free Tier (750 hrs/month
    for 12 months on a new account). t3.small is NOT free (~$0.0208/hr in
    eu-north-1, a few dollars/month) but gives 2GB RAM instead of 1GB, which
    Minikube --driver=docker wants more comfortably. Default stays on free tier;
    bump this var only when you're actively demoing the K8s deliverable.
  EOT
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Name for the AWS key pair created from your local public key."
  type        = string
  default     = "devops-lab-key"
}

variable "public_key_path" {
  description = "Path to your local SSH public key (e.g. ~/.ssh/id_ed25519.pub). Generate one if you don't have it: ssh-keygen -t ed25519 -f ~/.ssh/devops-lab"
  type        = string
  default     = "~/.ssh/devops_lab_key.pub"
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into the box. Set to your own IP/32 — never leave this at 0.0.0.0/0."
  type        = string
}

variable "project_name" {
  type    = string
  default = "devops-lab"
}
