resource "aws_vpc" "main" {
  cidr_block                       = "10.0.0.0/16"
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = true

  tags = {
    Name = "cka-vpc"
  }
}

resource "aws_subnet" "public-1a" {
  vpc_id                          = aws_vpc.main.id
  cidr_block                      = "10.0.128.0/24"
  availability_zone               = var.availability_zone_1a
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, 1)
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
    gateway_id      = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "cka-rt"
  }
}

resource "aws_route_table_association" "rta-public-1a" {
  subnet_id      = aws_subnet.public-1a.id
  route_table_id = aws_route_table.rt-public.id
}
