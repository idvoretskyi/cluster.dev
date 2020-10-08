terraform {
  required_version = "~> 0.13.4"
  required_providers {
    aws      = "~> 2.64.0"
    null     = "~> 2.1"
    helm     = "~> 1.0"
    random   = "~> 2.2"
    template = "~> 2.1"
    rke = {
      source  = "rancher/rke"
      version = "~> 1.1.3"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "helm" {
  kubernetes {
    config_path = var.kube_config_path
  }
}
