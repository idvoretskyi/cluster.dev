locals {
  cert-manager-version = "v1.0.2"
  crd-path             = "https://github.com/jetstack/cert-manager/releases/download"
}

resource "null_resource" "cert_manager_crds" {
  provisioner "local-exec" {
    command = "kubectl apply --kubeconfig ${var.kube_config_path} -n cert-manager --validate=false -f ${local.crd-path}/${local.cert-manager-version}/cert-manager.crds.yaml"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "exit 0"
  }
  triggers = {
    content = sha1("${local.crd-path}/${local.cert-manager-version}/cert-manager.crds.yaml")
  }
  depends_on = [
    local_file.kube_cluster_yaml
  ]
}


resource "null_resource" "cm_namespace" {
  provisioner "local-exec" {
    command = "until kubectl --kubeconfig ${local_file.kube_cluster_yaml.filename} create ns cert-manager ; do sleep 1; echo waiting kubernetes ready; done"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "exit 0"
  }
  depends_on = [
    local_file.kube_cluster_yaml
  ]
}

resource "helm_release" "cert_manager" {
  name          = "cert-manager"
  chart         = "cert-manager"
  repository    = "https://charts.jetstack.io"
  namespace     = "cert-manager"
  recreate_pods = true
  depends_on = [
    null_resource.cm_namespace,
    null_resource.cert_manager_crds,
  ]
}

