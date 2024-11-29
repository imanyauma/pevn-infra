# Create Bastion Host for connect to EKS and RDS
resource "aws_instance" "bastion" {
  ami =  "ami-0453ec754f44f9a4a"
  instance_type = "t2.medium"
  key_name = "food-order-bastion"
  subnet_id = var.subnet_id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.bastion-sg.id]
  ebs_block_device {
    volume_size = 30
    volume_type = "gp3"
    device_name = "/dev/xvda"
  }
  user_data = <<EOF
#!/bin/bash -xe
sudo yum install telnet git unzip -y
curl -LO https://dl.k8s.io/release/v1.25.2/bin/linux/amd64/kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
wget https://github.com/weaveworks/eksctl/releases/download/v0.140.0/eksctl_Linux_amd64.tar.gz
tar -xvzf eksctl_Linux_amd64.tar.gz
sudo mv eksctl /usr/local/bin/
wget https://get.helm.sh/helm-v3.12.0-rc.1-linux-amd64.tar.gz
tar -xvzf helm-v3.12.0-rc.1-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm
sudo yum install java-17-amazon-corretto.x86_64 -y
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum install -y  jenkins
systemctl start jenkins
systemctl enable jenkins
EOF
  tags = {
    "Name" = "Bastion Host"
  }
}

# Security Groups
resource "aws_security_group" "bastion-sg" {
  name        = "bastion_sg"
  description = "Allow SSH From Outside"
  vpc_id      = var.vpc_id
  ingress {
    description      = "Allow SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "Allow Tunneling"
    from_port        = 3000
    to_port          = 3000
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description = "Allow Jenkins"
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Bastion Security Group"
  }
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}