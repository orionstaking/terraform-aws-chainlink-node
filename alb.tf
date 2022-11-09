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

resource "aws_lb_target_group" "ui" {
  name                 = "chainlink-${var.environment}-ui"
  port                 = var.chainlink_ui_port
  protocol             = "TCP"
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = 10
  preserve_client_ip   = true

  health_check {
    enabled             = true
    path                = "/health"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    protocol            = "HTTP"
  }
}

resource "aws_lb_target_group" "node" {
  name                 = "chainlink-${var.environment}-node"
  port                 = var.chainlink_node_port
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
}

resource "aws_lb_listener" "ui" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.chainlink_ui_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ui.arn
  }
}

resource "aws_lb_listener" "node" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.chainlink_node_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.node.arn
  }
}
