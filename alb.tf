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
    # Generate a new id each time we change chainlink_ui_port
    port = var.tls_ui_enabled && var.tls_type == "import" ? var.tls_chainlink_ui_port : var.chainlink_ui_port
  }

  length  = 4
  upper   = false
  special = false
}

resource "random_string" "alb_prefix_node" {
  count = var.chainlink_p2p_networking_stack == "V1" || var.chainlink_p2p_networking_stack == "V1V2" ? 1 : 0

  keepers = {
    # Generate a new id each time we change chainlink_node_port_p2pv1
    port = var.chainlink_node_port_p2pv1
  }

  length  = 4
  upper   = false
  special = false
}

resource "random_string" "alb_prefix_node_v2" {
  count = var.chainlink_p2p_networking_stack == "V1V2" || var.chainlink_p2p_networking_stack == "V2" ? 1 : 0

  keepers = {
    # Generate a new id each time we change chainlink_node_port_p2pv2
    port = var.chainlink_node_port_p2pv2
  }

  length  = 2
  upper   = false
  special = false
}

resource "aws_lb_target_group" "ui" {
  name                 = "chainlink-${var.environment}-ui-${random_string.alb_prefix_ui.result}"
  port                 = var.tls_ui_enabled && var.tls_type == "import" ? var.tls_chainlink_ui_port : var.chainlink_ui_port
  protocol             = "TCP"
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = 10
  preserve_client_ip   = true

  health_check {
    enabled             = true
    path                = "/health"
    port                = var.chainlink_ui_port
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    protocol            = "HTTP"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "node" {
  count = var.chainlink_p2p_networking_stack == "V1" || var.chainlink_p2p_networking_stack == "V1V2" ? 1 : 0

  name                 = "chainlink-${var.environment}-node-${random_string.alb_prefix_node[0].result}"
  port                 = var.chainlink_node_port_p2pv1
  protocol             = "TCP"
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = 10
  preserve_client_ip   = true

  health_check {
    enabled             = true
    path                = "/health"
    port                = var.chainlink_ui_port
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
  count = var.chainlink_p2p_networking_stack == "V1V2" || var.chainlink_p2p_networking_stack == "V2" ? 1 : 0

  name                 = "chainlink-${var.environment}-nodev2-${random_string.alb_prefix_node_v2[0].result}"
  port                 = var.chainlink_node_port_p2pv2
  protocol             = "TCP"
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = 10
  preserve_client_ip   = true

  health_check {
    enabled             = true
    path                = "/health"
    port                = var.chainlink_ui_port
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
  load_balancer_arn = aws_lb.this.arn
  port              = var.tls_ui_enabled && var.tls_type == "import" ? var.tls_chainlink_ui_port : var.chainlink_ui_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ui.arn
  }
}

resource "aws_lb_listener" "node" {
  count = var.chainlink_p2p_networking_stack == "V1" || var.chainlink_p2p_networking_stack == "V1V2" ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = var.chainlink_node_port_p2pv1
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.node[0].arn
  }
}

resource "aws_lb_listener" "node_v2" {
  count = var.chainlink_p2p_networking_stack == "V1V2" || var.chainlink_p2p_networking_stack == "V2" ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = var.chainlink_node_port_p2pv2
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.node_v2[0].arn
  }
}
