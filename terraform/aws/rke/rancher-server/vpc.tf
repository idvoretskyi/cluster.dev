module "vpc" {
  create_vpc = "true"
  source     = "terraform-aws-modules/vpc/aws"
  version    = "2.15.0"

  name               = "rancher-vpc"
  cidr               = var.vpc_cidr
  azs                = var.availability_zones
  enable_nat_gateway = true
  enable_vpn_gateway = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnets = [for subnet_num, az in var.availability_zones : cidrsubnet(var.vpc_cidr, 4, subnet_num)]
  public_subnet_tags = {
    "kubernetes.io/role/elb"    = "1"
    "kubernetes.io/cluster/rke" = "owned"
  }
  private_subnets = [for subnet_num, az in var.availability_zones : cidrsubnet(var.vpc_cidr, 4, subnet_num + 4)]
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}
