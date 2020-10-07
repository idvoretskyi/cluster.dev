locals {
  cluster_id_tag = {
    "kubernetes.io/cluster/rke" = "owned"
  }
}

locals {
  rancher_ip = element(concat(aws_instance.rancher.*.private_ip, list("")), 0)
}

data "template_file" "init-rancher" {
  template = file("${path.module}/files/rancher-server.tpl.sh")

  vars = {
    ssh_public_keys = var.public_keys
    ssh_private_key = tls_private_key.rancher_key.private_key_pem
    disk            = "/dev/nvme1n1"
    datadir         = "/data"
  }
}

resource "aws_instance" "rancher" {
  ami                         = data.aws_ami.ubuntu20.id
  instance_type               = var.instance_type
  associate_public_ip_address = true
  user_data                   = data.template_file.init-rancher.rendered
  vpc_security_group_ids      = [module.rancher_sg.this_security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  iam_instance_profile        = aws_iam_instance_profile.rke-aws.name
  tags = {
    Name                        = "rancher-server"
    MAINTAINER                  = "SHALB"
    CREATOR                     = "Terraform"
    "kubernetes.io/cluster/rke" = "owned"
  }
  root_block_device {
    volume_size = 40
  }
  depends_on = [
    module.vpc,
    module.rancher_sg
  ]
}

resource "aws_eip" "rancher_elastic_ip" {
  instance = aws_instance.rancher.id
  vpc      = true
}

module "rancher_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "3.1.0"

  name        = "rancher-server"
  description = "rancher server with"
  vpc_id      = module.vpc.vpc_id
  tags        = local.cluster_id_tag

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "External rancher Access"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 6443
      to_port     = 6443
      protocol    = "tcp"
      description = "External rancher Access"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 10248
      to_port     = 10248
      protocol    = "tcp"
      description = "External rancher Access"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "External rancher Access"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "External rancher Access"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

resource "tls_private_key" "rancher_key" {
  algorithm = "RSA"
}

data "aws_ami" "ubuntu20" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}

resource "null_resource" "wait_instance_ready" {
  provisioner "local-exec" {
    command = "until ssh -i ${var.ssh_priv_key} -o StrictHostKeyChecking=no root@${aws_eip.rancher_elastic_ip.public_ip} docker version; do sleep 1; echo waiting instance ready; done"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "exit 0"
  }
  depends_on = [
    aws_instance.rancher
  ]
}

