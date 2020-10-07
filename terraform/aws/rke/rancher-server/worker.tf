data "template_file" "init-rancher-worker" {
  template = file("${path.module}/files/rancher-worker.tpl.sh")

  vars = {
    ssh_public_keys     = var.public_keys
    ssh_private_key     = tls_private_key.rancher_key.private_key_pem
    rancher_domain      = local.rancher_domain
    rancher_password    = random_password.rancher_pass.result
  }
  depends_on = [
    null_resource.configure_rancher
  ]
}

resource "aws_instance" "rancher_worker" {
  ami                         = data.aws_ami.ubuntu20.id
  instance_type               = var.instance_type
  associate_public_ip_address = true
  user_data                   = data.template_file.init-rancher-worker.rendered
  vpc_security_group_ids      = [module.rancher_sg.this_security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  iam_instance_profile        = aws_iam_instance_profile.rke-aws.name
  tags = {
    Name                        = "rancher-worker"
    MAINTAINER                  = "SHALB"
    CREATOR                     = "Terraform"
    "kubernetes.io/cluster/rke" = "owned"
  }
  root_block_device {
    volume_size = 40
  }
  depends_on = [
    data.template_file.init-rancher-worker
  ]
}

resource "aws_eip" "rancher_worker_elastic_ip" {
  instance = aws_instance.rancher_worker.id
  vpc      = true
}
