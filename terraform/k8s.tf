resource "aws_instance" "k8s-control" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t3a.medium"
  ipv6_address_count = 1
  subnet_id = aws_subnet.public-1a.id
  associate_public_ip_address = true
  key_name = "cka"
  security_groups = [aws_security_group.cka-sg.id]
  tags = {
    Name = "k8s"
  }
}

resource "aws_route53_record" "k8s-control-r53rec" {
  zone_id = var.hosted_zone_id
  name = "k8s-control.curtisnoel.net"
  type = "A"
  ttl = "300"
  records = [aws_instance.cka-master.public_ip]
}
