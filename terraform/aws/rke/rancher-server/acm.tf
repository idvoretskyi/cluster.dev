data "aws_route53_zone" "main_zone" {
  name         = var.acm_domain
  private_zone = false
}

resource "aws_acm_certificate" "wildcard_main_cert" {
  domain_name       = "*.rke.${var.acm_domain}"
  validation_method = "DNS"
}

resource "aws_route53_record" "cert_validation" {
  name    = aws_acm_certificate.wildcard_main_cert.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.wildcard_main_cert.domain_validation_options.0.resource_record_type
  zone_id = data.aws_route53_zone.main_zone.id
  records = [aws_acm_certificate.wildcard_main_cert.domain_validation_options.0.resource_record_value]
  ttl     = 600
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.wildcard_main_cert.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
}
