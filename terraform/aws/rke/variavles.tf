variable "awsprofile" {
  type        = string
  default     = "default"
  description = "The aws credential profile alias in ~/.aws/credentials"
}

variable "azs" {
  type        = list
  description = "Availability Zones to deploy cluster"
}

variable "region" {
  type        = string
  description = "The AWS region."
}

variable "instance_type" {
  type        = string
  description = "The AWS region."
}

variable "domain" {
  type    = string
  default = "lf.shalb.net"
}