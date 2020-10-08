variable "acm_domain" {
}

variable "ssh_priv_key" {
  description = "Private key file name for ssh connection."
  default     = "~/.ssh/id_rsa"
}

variable "kube_config_path" {
  default = "./kube_config_cluster.yml"
}

variable "instance_type" {
  description = "Instance size"
}

variable "public_keys" {}

variable "data_volume_size" {
  description = "Size of /data/ volume"
  default     = 20
}

variable "region" {
  type        = string
  description = "The AWS region."
}

variable "availability_zones" {
  type        = list
  description = "The AWS Availability Zone inside region."
}

variable "vpc_cidr" {
  type        = string
  description = "Vpc CIDR"
  default     = "10.8.0.0/18"
}
