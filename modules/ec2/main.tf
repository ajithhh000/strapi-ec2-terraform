# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Generate SSH key pair
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.ssh.public_key_openssh
}

# Security group in default VPC
resource "aws_security_group" "strapi" {
  name        = "${var.project_name}-sg"
  description = "Security group for Strapi"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Strapi"
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}

# EC2 instance
resource "aws_instance" "strapi" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.deployer.key_name

  vpc_security_group_ids = [aws_security_group.strapi.id]

  user_data = <<-EOF
              #!/bin/bash
              set -e

              # Log everything for debugging
              exec > >(tee /var/log/user-data.log)
              exec 2>&1

              echo "=== Installing Strapi Dependencies ==="
              echo "Timestamp: $(date)"

              # Update package manager
              apt-get update -y

              # Install essential build tools and dependencies
              apt-get install -y git curl build-essential python3 python3-pip

              # Install Node.js 20.x LTS from NodeSource
              curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
              apt-get install -y nodejs

              # Verify installations
              echo "Node version: $(node --version)"
              echo "NPM version: $(npm --version)"

              # Install PM2 globally for process management
              npm install -g pm2

              # Install Yarn (optional but recommended for Strapi)
              npm install -g yarn

              echo "=== Dependencies Installation Complete ==="
              echo "Timestamp: $(date)"
              EOF

  tags = {
    Name = "${var.project_name}-instance"
  }
}

# Get latest Amazon Linux 2 AMI for ap-south-1
data "aws_ami" "ubuntu" {
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
