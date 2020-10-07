output "public_ip" {
  value = aws_eip.rancher_elastic_ip.public_ip
}

output "public_key_openssh" {
  value = tls_private_key.rancher_key.public_key_openssh
}

output "public_key_pem" {
  value = tls_private_key.rancher_key.private_key_pem
}

output "rancher_url" {
  value       = "https://${local.rancher_domain}"
  description = "Rancher URL"
}

output "rancher_password" {
  value       = random_password.rancher_pass.result
  description = "Rancher Password for 'admin' user"
}

