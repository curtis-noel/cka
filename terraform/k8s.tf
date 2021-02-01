data "template_file" "k8s-control-user-data" {
  template = file("${path.module}/template/k8s-control-user-data.sh.tpl")

  vars = {
    #aws_region                       = var.aws_region
  }
}

resource "aws_instance" "k8s-control" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3a.xlarge"
  ipv6_address_count          = 1
  subnet_id                   = aws_subnet.public-1a.id
  associate_public_ip_address = true
  key_name                    = "cka"
  security_groups             = [aws_security_group.k8s-control-sg.id]
  user_data                   = data.template_file.k8s-control-user-data.rendered
  tags = {
    Name = "k8s"
  }
}

# resource "aws_route53_record" "k8s-control-r53rec" {
#   zone_id = var.hosted_zone_id
#   name    = var.k8s_control_name
#   type    = "A"
#   ttl     = "300"
#   records = [aws_instance.k8s-control.public_ip]
# }

resource "aws_security_group" "k8s-control-sg" {
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
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }
}

