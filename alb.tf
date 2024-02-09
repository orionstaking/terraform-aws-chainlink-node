resource "aws_lb" "this" {
  name               = "chainlink-${var.environment}-node"
  internal           = false
  load_balancer_type = "network"

  dynamic "subnet_mapping" {
    for_each = { for subnet_map in var.subnet_mapping : subnet_map.subnet_id => subnet_map }
    content {
      subnet_id     = subnet_mapping.value.subnet_id
      allocation_id = subnet_mapping.value.allocation_id
    }
  }

  tags = {
    Name = "${var.project}-${var.environment}-node"
  }
}

resource "random_string" "alb_prefix_ui" {
  keepers = {
    # Generate a new id each time we change ui_port
    port = local.tls_import ? local.tls_ui_port : local.ui_port
  }

  length  = 4
  upper   = false
  special = false
}

resource "random_string" "alb_prefix_node_v2" {
  count = local.networking_stack == "V2" ? 1 : 0

  keepers = {
    # Generate a new id each time we change announce_port_v2
    port = local.announce_port_v2
  }

  length  = 2
  upper   = false
  special = false
}

resource "aws_lb_target_group" "ui" {
  name                 = "chainlink-${var.environment}-ui-${random_string.alb_prefix_ui.result}"
  port                 = local.tls_import ? local.tls_ui_port : local.ui_port
  protocol             = "TCP"
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = 10
  preserve_client_ip   = true

  health_check {
    enabled             = true
    path                = "/health"
    port                = local.ui_port
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    protocol            = "HTTP"
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_lb_target_group" "node_v2" {
  count = local.networking_stack == "V2" ? 1 : 0

  name                 = "chainlink-${var.environment}-nodev2-${random_string.alb_prefix_node_v2[0].result}"
  port                 = local.announce_port_v2
  protocol             = "TCP"
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = 10
  preserve_client_ip   = true

  health_check {
    enabled             = true
    path                = "/health"
    port                = local.ui_port
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    protocol            = "HTTP"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "ui" {
  count = var.route53_enabled ? 0 : 1

  load_balancer_arn = aws_lb.this.arn
  port              = local.tls_import ? local.tls_ui_port : local.ui_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ui.arn
  }
}

resource "aws_lb_listener" "node_v2" {
  count = local.networking_stack == "V2" ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = local.announce_port_v2
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.node_v2[0].arn
  }
}

resource "aws_lb_listener" "ui_secure" {
  count = var.route53_enabled ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "TLS"
  certificate_arn   = module.acm[0].acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ui.arn
  }
}

resource "aws_route53_record" "this" {
  count = var.route53_enabled ? 1 : 0

  zone_id = var.route53_zoneid
  name    = "${var.route53_subdomain_name}.${var.route53_domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_lb.this.dns_name]
}

module "acm" {
  count = var.route53_enabled ? 1 : 0

  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  domain_name = "${var.route53_subdomain_name}.${var.route53_domain_name}"
  zone_id     = var.route53_zoneid

  wait_for_validation = true
}
