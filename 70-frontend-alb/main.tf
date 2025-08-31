module "ingress_alb" {
  source = "terraform-aws-modules/alb/aws"
  version = "9.16.0"
  internal = false
  name = "${var.project}-${var.environment}-ingress-alb"
  create_security_group = false
  security_groups = [local.ingress_alb_sg_id]
  subnets = local.public_subnet_id
  enable_deletion_protection = false
  tags = merge(
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}-ingress-alb"
    }
  )
}

resource "aws_lb_listener" "ingress_alb_listener" {
    load_balancer_arn = module.ingress_alb.arn
    port = "443"
    protocol = "HTTPS"
    certificate_arn = local.acm_certificate_arn
    default_action {
        type = "fixed-response"

        fixed_response {
        content_type = "text/html"
        message_body = "<h1>Hello, I am from ingress ALB using HTTPS</h1>"
        status_code  = "200"
        }
    }
}

resource "aws_route53_record" "ingress_alb" {
    zone_id = var.route53_zone_id
    name = "${var.environment}.${var.route53_domain_name}"
    type = "A"
    alias {
        name = module.ingress_alb.dns_name
        zone_id = module.ingress_alb.zone_id
        evaluate_target_health = true
    }
}

resource "aws_lb_target_group" "frontend" {
    name = "${var.project}-${var.environment}-frontend"
    port = 8080 # here for catalogue  port 8080 will be allowed here backend component runs on port 8080
    protocol = "HTTP" # load balancer will hit on this protocol for catalogue to allow
    vpc_id = local.vpc_id
    health_check {
        healthy_threshold = 2 #Number of consecutive health check successes required before considering a target healthy. The range is 2-10. Defaults to 3.
        interval = 5 # Approximate amount of time, in seconds, between health checks of an individual target. The range is 5-300
        matcher = "200-299" # response code for health check it ranges from 200-299
        path = "/" # checking the health of the catalogue component
        port = 8080 # port which catalogue component is allowed
        timeout = 2 # after hitting the URL before 5 seconds we should get response or it is unhealthy
        unhealthy_threshold = 3 # to check the health of the instane we will use this if the instance fails after 3 attempts then it will mark it as unhealthy
    }   
}

resource "aws_lb_listener_rule" "listener" {
    listener_arn = aws_lb_listener.ingress_alb_listener.arn # getting listener arn
    priority     = 10 
    action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.frontend.arn # here forwarding the traffic to target group
    }
    condition {
        host_header {
                values = ["${var.environment}.${var.route53_domain_name}"] # dev.pavithra.fun when anyone hits this URL forward to target group
        }
    }
}