resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "k8s-vpc"
  }
}

resource "aws_subnet" "public-1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.128.0/24"
  availability_zone = var.availability_zone_1a
  tags = {
    Name = "k8s-public-1a"
  }
}

resource "aws_subnet" "public-1b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.129.0/24"
  availability_zone = var.availability_zone_1b
  tags = {
    Name = "k8s-public-1b"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "k8s-igw"
  }
}

resource "aws_route_table" "rt-public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "k8s-rt"
  }
}

resource "aws_route_table_association" "rta-public-1a" {
  subnet_id      = aws_subnet.public-1a.id
  route_table_id = aws_route_table.rt-public.id
}
