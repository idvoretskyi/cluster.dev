variable "rancher_public_keys" {
  type = map
  default = {
    shalb-voa  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCi6UIVruH0CfKewYlSjA7oR6gjahZrkJ+k/0cj46nvYrORVcds2cijZPT34ACWkvXV8oYvXGWmvlGXV5H1sD0356zpjhRnGo6j4UZVS6KYX5HwObdZ6H/i+A9knEyXxOCyo6p4VeJIYGhVYcQT4GDAkxb8WXHVP0Ax/kUqrKx0a2tK9JjGkuLbufQc3yWhqcfZSVRU2a+M8f8EUmGLOc2VEi2mGoxVgikrelJ0uIGjLn63L6trrsbvasoBuILeXOAO1xICwtYFek/MexQ179NKqQ1Wx/+9Yx4Xc63MB0vR7kde6wxx2Auzp7CjJBFcSTz0TXSRsvF3mnUUoUrclNkr voa@auth.shalb.com"
    shalb-arti = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC872U0xIGtOQRXhOXHITkSDBhHsk5jxYX8YvXqsYh86AjONbHf/dvukJdUoTErmc9EcWJ3NshHlZbc+EMXULzuGlgQDGqwTQxKBXFbMX4u9p3ZCwDtQJqL15JTpIJ7UjWAlSbnOeqidLEIG1K7aiY+hbVSg/dIZ6od0RtJCicZrP0LSGnqR6OJZOlKN9ryFJ51z2V+OIPjyOpjfVZQXoO8KYBBFF8OhfDHUBFR/VolNEQedj9hLfd+rIuEwSlAPBnx6GQkgwp1JwOGXIlizklBHdOHqUB3QAPdt5mILNgwDvon0eb38jjapV6nJgSH1BASBt8l64LA6SGUSAOENCv3 arti@auth.shalb.com"
  }
}

module "rancher-server" {
  source             = "./rancher-server/"
  region             = var.region
  instance_type      = var.instance_type
  availability_zones = var.azs
  public_keys        = replace(join(",", values(var.rancher_public_keys)), ",", "\n")
  acm_domain         = var.domain
  data_volume_size   = "20"
}

resource "aws_key_pair" "rancher" {
  key_name   = "rancher"
  public_key = module.rancher-server.public_key_openssh
}

output "server_ip" {
  value = module.rancher-server.public_ip
}

output "rancher_url" {
  value = module.rancher-server.rancher_url
}

output "rancher_password" {
  value = module.rancher-server.rancher_password
}