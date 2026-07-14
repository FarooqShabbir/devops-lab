data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "lab_key" {
  key_name   = var.key_pair_name
  public_key = file(var.public_key_path)
}

# --- IAM: least-privilege role for the instance (no admin, no static keys needed on box) ---
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# Read-only access to pull from a future ECR repo if you migrate off GHCR later.
resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "lab_host" {
  ami                         = data.aws_ami.ubuntu_2204.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.lab_sg.id]
  key_name                    = aws_key_pair.lab_key.key_name
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true

  # gp3 free tier covers up to 30GB; Docker images + Minikube need real room.
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 29
    delete_on_termination = true
    encrypted              = true
  }

  user_data = file("${path.module}/../ansible/bootstrap.sh")

  tags = {
    Name    = "${var.project_name}-host"
    Project = var.project_name
  }
}

resource "aws_eip" "lab_eip" {
  domain   = "vpc"
  instance = aws_instance.lab_host.id
  tags     = { Name = "${var.project_name}-eip" }
}
