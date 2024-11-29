#VPC
resource "aws_vpc" "food-order" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "Food Order"
  }
}

#Create Public Subnet 1 & 2
resource "aws_subnet" "public-subnet-1" {
  vpc_id                  = aws_vpc.food-order.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "Public Subnet 1"
  }
}
resource "aws_subnet" "public-subnet-2" {
  vpc_id                  = aws_vpc.food-order.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"
  tags = {
    Name = "Public Subnet 2"
  }
}

#Create App Subnet 1 & 2
resource "aws_subnet" "app-subnet-1" {
  vpc_id                  = aws_vpc.food-order.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1a"
  tags = {
    Name = "App Subnet 1"
  }
}
resource "aws_subnet" "app-subnet-2" {
  vpc_id                  = aws_vpc.food-order.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1b"
  tags = {
    Name = "App Subnet 2"
  }
}

#Create Internet Gateway and attach to VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.food-order.id
  tags = {
    Name = "IGW"
  }
}

# Create two Elastic IP for NAT Gateway
resource "aws_eip" "eip-1" {
  vpc = true
}
resource "aws_eip" "eip-2" {
  vpc = true
}

# Create two NAT Gateway for each AZ
resource "aws_nat_gateway" "nat-gw-1" {
  allocation_id = aws_eip.eip-1.id
  subnet_id     = aws_subnet.public-subnet-1.id
  tags = {
    Name = "NATGateway1"
  }
}
resource "aws_nat_gateway" "nat-gw-2" {
  allocation_id = aws_eip.eip-2.id
  subnet_id     = aws_subnet.public-subnet-2.id
  tags = {
    Name = "NATGateway2"
  }
}

#Create Public Route Table
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.food-order.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "Public Route Table"
  }
}

#Create App Route Table
resource "aws_route_table" "app-route-table-az1" {
  vpc_id = aws_vpc.food-order.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw-1.id
  }
  tags = {
    Name = "App Route Table AZ1"
  }
}
resource "aws_route_table" "app-route-table-az2" {
  vpc_id = aws_vpc.food-order.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw-2.id
  }
  tags = {
    Name = "App Route Table AZ2"
  }
}

#Associate Public Route Table with Public Subnets
resource "aws_route_table_association" "public-route-table-1" {
  subnet_id      = aws_subnet.public-subnet-1.id
  route_table_id = aws_route_table.public-route-table.id
}
resource "aws_route_table_association" "public-route-table-2" {
  subnet_id      = aws_subnet.public-subnet-2.id
  route_table_id = aws_route_table.public-route-table.id
}

#Associate App and Database Subnets with App Route AZ1
resource "aws_route_table_association" "app-route-table-az1" {
  subnet_id      = aws_subnet.app-subnet-1.id
  route_table_id = aws_route_table.app-route-table-az1.id
}

#Associate App and Database Subnets with App Route AZ2
resource "aws_route_table_association" "app-route-table-az2" {
  subnet_id      = aws_subnet.app-subnet-2.id
  route_table_id = aws_route_table.app-route-table-az2.id
}

# Security Groups
resource "aws_security_group" "app-sg" {
  name        = "app_sg"
  description = "Allow HTTP From Outside"
  vpc_id      = aws_vpc.food-order.id
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


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "App Security Group"
  }
}

resource "aws_security_group" "rds-sg" {
  name        = "rds-sg"
  description = "Allow Apps to Access RDS"
  vpc_id      = aws_vpc.food-order.id
}

resource "aws_security_group_rule" "allow-rds-from-app" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.rds-sg.id
}

module "pevn-db" {
  source = "./modules/pevn-db"
  subnet_id_a = aws_subnet.app-subnet-1.id
  subnet_id_b = aws_subnet.app-subnet-2.id
  rds-sg = aws_security_group.rds-sg.id
}

module "pevn-s3-cloudfront" {
  source = "./modules/pevn-s3-cloudfront"
  region = "us-east-1"
  s3_name = "pevn-tutorial-logicque-onaws"
}

module "pevn_ecs" {
  source = "./modules/pevn-ecs"
  ecs_vpc = aws_vpc.food-order.id
  vpc_zone1_identifier = aws_subnet.app-subnet-1.id
  vpc_zone2_identifier = aws_subnet.app-subnet-2.id
}

module "bastion-host" {
  source = "./modules/bastion-host"
  subnet_id = aws_subnet.public-subnet-1.id
  app-sg = aws_security_group.app-sg.id
  vpc_id = aws_vpc.food-order.id
  aws_s3_bucket = module.pevn-s3-cloudfront.s3_name
}

