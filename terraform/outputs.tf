output "k8s-control-node" {
  value = aws_instance.k8s_master.public_ip
}

