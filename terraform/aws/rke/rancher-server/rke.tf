resource "rke_cluster" "cluster" {
  cloud_provider {
    name = "aws"
  }
  nodes {
    address          = aws_eip.rancher_elastic_ip.public_ip
    internal_address = local.rancher_ip
    user             = "root"
    ssh_key          = file(var.ssh_priv_key)
    role             = ["controlplane", "worker", "etcd"]
  }
  ingress {
    provider         = "nginx"
    options          = {
      "use-forwarded-headers" = "true"
    }
    extra_args       = {
      "report-node-internal-ip-address" = ""
    }
  }
  depends_on = [null_resource.wait_instance_ready, module.vpc]
}

resource "local_file" "kube_cluster_yaml" {
  filename = var.kube_config_path
  content  = rke_cluster.cluster.kube_config_yaml
}
