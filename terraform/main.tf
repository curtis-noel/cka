provider "aws" {
  region = "us-east-1"
}


terraform {
  backend "s3" {
    bucket = "cnoel-cka"
    key    = "tfstate"
    region = "us-east-1"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["aws-marketplace"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64*"]
  }
}

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  assign_generated_ipv6_cidr_block = true

  tags = {
    Name = "cka-vpc"
  }
}

resource "aws_subnet" "public-1a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.128.0/24"
  availability_zone = "us-east-1a"
  ipv6_cidr_block = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, 1)
  assign_ipv6_address_on_creation = true
  tags = {
    Name = "cka-public-1a"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "cka-igw"
  }
}

resource "aws_route_table" "rt-public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "cka-rt"
  }
}

resource "aws_route_table_association" "rta-public-1a" {
  subnet_id      = aws_subnet.public-1a.id
  route_table_id = aws_route_table.rt-public.id
}

resource "aws_security_group" "cka-sg" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_instance" "cka-master" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3a.medium"
  ipv6_address_count = 1
  subnet_id = aws_subnet.public-1a.id
  associate_public_ip_address = true
  key_name = "cka"
  security_groups = [aws_security_group.cka-sg.id]
  tags = {
    Name = "cka-master"
  }
}

resource "aws_route53_record" "cka_master-r53rec" {
  zone_id = "Z1UKXVYYQ8MSN8"
  name = "k8s-control.curtisnoel.net"
  type="A"
  ttl="300"
  records = [aws_instance.cka-master.public_ip]
}

#aws s3api create-bucket --bucket cnoel-cka --region us-east-1
#aws s3api put-bucket-encryption --bucket cnoel-cka  --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'
#aws s3api put-object --bucket  cnoel-cka  --key tfstate
#aaws ec2 create-key-pair --key-name cka --query 'KeyMaterial' --output text > cka.pem
