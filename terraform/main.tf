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

#aws s3api create-bucket --bucket cnoel-cka --region us-east-1
#aws s3api put-bucket-encryption --bucket cnoel-cka  --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'
#aws s3api put-object --bucket  cnoel-cka  --key tfstate
#aaws ec2 create-key-pair --key-name cka --query 'KeyMaterial' --output text > ~/cka.pem
