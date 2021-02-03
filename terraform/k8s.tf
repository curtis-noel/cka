data "template_file" "k8s-control-user-data" {
  template = file("${path.module}/template/k8s-control-user-data.sh.tpl")

  vars = {
    #aws_region                       = var.aws_region
  }
}

resource "aws_instance" "k8s_master" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3a.xlarge"
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

resource "aws_lb" "k8s_load_balancer" {
  name               = "k8s-aws-lb"
  load_balancer_type = "network"
  internal           = true
  subnets            = [aws_subnet.public-1a.id, aws_subnet.public-1b.id]
}

resource "aws_lb_listener" "k8s_listener" {
  load_balancer_arn = aws_lb.k8s_load_balancer.arn
  port              = 6443
  protocol          = "TCP"
  default_action {
    target_group_arn = aws_lb_target_group.k8s_tg.arn
    type             = "forward"
  }
}
resource "aws_lb_target_group" "k8s_tg" {
  name                 = "k8s-tg"
  port                 = 6443
  protocol             = "TCP"
  vpc_id               = aws_vpc.main.id
  target_type          = "instance"
  deregistration_delay = 90
  health_check {
    interval            = 10
    port                = 6443
    protocol            = "TCP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}
resource "aws_lb_target_group_attachment" "k8s_tga_master" {
  target_group_arn = aws_lb_target_group.k8s_tg.arn
  port             = 6443
  target_id        = aws_instance.k8s_master.id
}

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

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "TCP"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

