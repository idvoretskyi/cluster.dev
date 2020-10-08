# resource "aws_security_group" "rke_ingress" {
#   name_prefix = "rancher"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_lb" "alb_ingress" {
#   name               = "rancher-lb"
#   internal           = false
#   load_balancer_type = "network"

#   subnets = [
#     module.vpc.public_subnets[0],
#     module.vpc.public_subnets[1],
#   ]
#   security_groups = [
#     aws_security_group.rke_ingress.id,
#     module.vpc.default_security_group_id,
#   ]
# }

# # Create a target group to forward traffic to rke-ingress port
# resource "aws_alb_target_group" "rke_ingress" {
#   name     = "rke-cluster"
#   port     = 80
#   protocol = "HTTP"
#   vpc_id   = module.vpc.vpc_id
#   health_check {
#     enabled = true
#     matcher = "200-499"
#   }
# }

# resource "aws_alb_target_group_attachment" "rke_alb" {
#   target_group_arn = aws_alb_target_group.rke_ingress.arn
#   target_id        = aws_instance.rancher.id
#   port             = 80
# }


# resource "aws_lb_listener" "https_ingress" {
#   load_balancer_arn = aws_lb.alb_ingress.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
#   certificate_arn   = aws_acm_certificate.wildcard_main_cert.arn

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_alb_target_group.rke_ingress.arn
#   }
# }

# resource "aws_lb_listener" "http_ingress" {
#   load_balancer_arn = aws_lb.alb_ingress.arn
#   port              = "80"
#   protocol          = "TCP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.rke_ingress.arn
#   }

  # default_action {
  #   type = "redirect"

  #   redirect {
  #     port        = "443"
  #     protocol    = "HTTPS"
  #     status_code = "HTTP_301"
  #   }
  # }
# }

# output "ingress_alb" {
#   value = aws_lb.alb_ingress.dns_name
# }

data "aws_elb_hosted_zone_id" "main" {}

resource "aws_route53_record" "alb_ingress" {
  zone_id = data.aws_route53_zone.main_zone.id
  name    = local.rancher_domain
  type    = "A"
  ttl     = 300
  records = [aws_eip.rancher_elastic_ip.public_ip]
  # alias {
  #   name                   = aws_lb.alb_ingress.dns_name
  #   zone_id                = data.aws_elb_hosted_zone_id.main.id
  #   evaluate_target_health = false
  # }
}