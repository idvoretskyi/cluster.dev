locals {
  rancher_domain = "rancher2.rke.${var.acm_domain}"
}

resource "random_password" "rancher_pass" {
  length  = 16
  special = false
}
resource "null_resource" "rancher_namespace" {
  provisioner "local-exec" {
    command = "until kubectl --kubeconfig ${local_file.kube_cluster_yaml.filename} create ns cattle-system ; do sleep 1; echo waiting kubernetes ready; done"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "exit 0"
  }
  depends_on = [
    local_file.kube_cluster_yaml
  ]
}
# kube_config_cluster.yml
# Deploy  with Helm provider
resource "helm_release" "rancher" {
  name       = "rancher"
  repository = "https://releases.rancher.com/server-charts/stable"
  chart      = "rancher"
  namespace  = "cattle-system"
  depends_on = [
    null_resource.rancher_namespace
  ]
  set {
    name  = "tls"
    value = "external"
  }
  set {
    name  = "hostname"
    value = local.rancher_domain
  }
}

data "template_file" "configure_rancher" {
  template = file("${path.module}/files/set_pass.tpl.sh")

  vars = {
    rancher_domain = local.rancher_domain
    rancher_password = random_password.rancher_pass.result
  }
}

resource "null_resource" "wait_rancher_ready" {
  provisioner "local-exec" {
    command = "until curl -s 'https://${local.rancher_domain}/'; do sleep 2; echo waiting rancher ready; done"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "exit 0"
  }
  depends_on = [
    helm_release.rancher
  ]
}


resource "null_resource" "configure_rancher" {
  provisioner "local-exec" {
    command = data.template_file.configure_rancher.rendered
  }
  provisioner "local-exec" {
    when    = destroy
    command = "exit 0"
  }
  depends_on = [
    null_resource.wait_rancher_ready
  ]
}