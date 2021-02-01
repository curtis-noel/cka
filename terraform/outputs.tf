output "k8s-control-node" {
  value = aws_instance.k8s-control.public_ip
}

