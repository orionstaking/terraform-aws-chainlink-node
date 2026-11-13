locals {
  container_insights_monitoring = var.monitoring_enabled ? "enabled" : "disabled"

  env_vars = flatten([
    for key, value in var.env_vars : [{
      name  = key
      value = value
    }]
  ])

  tf_announce_ips = [
    for subnet in var.subnet_mapping : subnet.ip
  ]
}

# TOML config parse
data "external" "parse_config" {
  program = ["python3", "${path.module}/parse_config.py"]
  query = {
    tf_announce_ips  = join(",", local.tf_announce_ips)
    config_secret_id = var.config_plain_secret_arn
    aws_region       = var.aws_region
  }
}

locals {
  ui_port          = data.external.parse_config.result.http_port
  announce_port_v2 = element(split(":", element(split(",", data.external.parse_config.result.announce_addresses), 0)), 1)
  listen_port_v2   = element(split(":", data.external.parse_config.result.listen_addresses), 1)

  nlb_subnet_cidrs = sort([for subnet in data.aws_subnet.nlb : subnet.cidr_block])
  access_ports = {
    ui           = local.ui_port
    otel_metrics = 8888
    otel_health  = 13133
  }
  ingress_whitelist_rules = {
    for rule in flatten([
      for entry in var.ingress_whitelist : [
        for access in entry.access : {
          key         = "${entry.cidr}-${access}"
          cidr        = entry.cidr
          description = entry.description
          access      = access
        }
      ]
    ]) : rule.key => rule
  }
}

# ECS cluster
resource "aws_ecs_cluster" "this" {
  name = "${var.project}-${var.environment}-node"
  setting {
    name  = "containerInsights"
    value = local.container_insights_monitoring
  }
}

resource "aws_ecs_task_definition" "this" {
  family = "${var.project}-${var.environment}-node"

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory

  execution_role_arn = aws_iam_role.this.arn

  container_definitions = templatefile(
    "${path.module}/templates/node_task_definition.json.tpl",
    {
      project          = var.project
      environment      = var.environment
      docker_image     = "${var.node_image_source}:${var.node_version}"
      aws_region       = var.aws_region
      ui_port          = local.ui_port
      announce_port_v2 = local.announce_port_v2
      listen_port_v2   = local.listen_port_v2
      task_cpu         = var.task_cpu
      task_memory      = var.task_memory
      env_vars         = local.env_vars
      config           = var.config_plain_secret_arn
      secrets          = var.secrets_plain_secret_arn
      init_script = replace(
        replace(trimsuffix(file("${path.module}/templates/init_script.sh.tpl"), "\n"), "\n", " && "),
        "\"",
        "\\\"",
      )
      otel_init_script = replace(file("${path.module}/templates/otel_init_script.sh.tpl"), "\n", " && ")
      otel_config      = aws_secretsmanager_secret.otel_config.arn
    }
  )
}

# ECS service
resource "aws_ecs_service" "this" {
  name                               = "${var.project}-${var.environment}-node"
  cluster                            = aws_ecs_cluster.this.id
  task_definition                    = aws_ecs_task_definition.this.arn
  deployment_maximum_percent         = "100"
  deployment_minimum_healthy_percent = "0"

  launch_type   = "FARGATE"
  desired_count = 1

  network_configuration {
    subnets          = var.vpc_private_subnets
    security_groups  = [aws_security_group.this.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ui.arn
    container_name   = "${var.project}-${var.environment}-node"
    container_port   = local.ui_port
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.otel_health.arn
    container_name   = "${var.project}-${var.environment}-otel"
    container_port   = 13133
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.otel_metrics.arn
    container_name   = "${var.project}-${var.environment}-otel"
    container_port   = 8888
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.node_v2.arn
    container_name   = "${var.project}-${var.environment}-node"
    container_port   = local.listen_port_v2
  }
}

# Log groups to store logs from Node
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/ecs/${var.project}-${var.environment}-node"
  retention_in_days = 7
}

# Log groups to store logs from OTEL
resource "aws_cloudwatch_log_group" "otel" {
  name              = "/aws/ecs/${var.project}-${var.environment}-otel"
  retention_in_days = 7
}

data "aws_subnet" "nlb" {
  for_each = toset([for subnet in var.subnet_mapping : subnet.subnet_id])
  id       = each.value
}

# SG for ECS Tasks
resource "aws_security_group" "this" {
  name        = "${var.project}-${var.environment}-node-ecs-tasks"
  description = "Allow trafic between alb and Chainlink Node"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "ingress_allow_otel_health" {
  type        = "ingress"
  from_port   = 13133
  to_port     = 13133
  protocol    = "tcp"
  cidr_blocks = local.nlb_subnet_cidrs
  description = "NLB subnets"

  security_group_id = aws_security_group.this.id
}

resource "aws_security_group_rule" "ingress_allow_otel_metrics" {
  type        = "ingress"
  from_port   = 8888
  to_port     = 8888
  protocol    = "tcp"
  cidr_blocks = local.nlb_subnet_cidrs
  description = "NLB subnets"

  security_group_id = aws_security_group.this.id
}

resource "aws_security_group_rule" "ingress_allow_node_v2" {
  type        = "ingress"
  from_port   = local.announce_port_v2
  to_port     = local.announce_port_v2
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.this.id
}

resource "aws_security_group_rule" "ingress_allow_ui" {
  type        = "ingress"
  from_port   = local.ui_port
  to_port     = local.ui_port
  protocol    = "tcp"
  cidr_blocks = local.nlb_subnet_cidrs
  description = "NLB subnets"

  security_group_id = aws_security_group.this.id
}

resource "aws_security_group_rule" "ingress_allow_ui_vpc" {
  count = var.allow_ui_from_vpc ? 1 : 0

  type        = "ingress"
  from_port   = local.ui_port
  to_port     = local.ui_port
  protocol    = "tcp"
  cidr_blocks = [var.vpc_cidr_block]
  description = "VPC CIDR"

  security_group_id = aws_security_group.this.id
}

resource "aws_security_group_rule" "ingress_whitelist" {
  for_each = local.ingress_whitelist_rules

  type        = "ingress"
  from_port   = local.access_ports[each.value.access]
  to_port     = local.access_ports[each.value.access]
  protocol    = "tcp"
  cidr_blocks = [each.value.cidr]
  description = each.value.description

  security_group_id = aws_security_group.this.id
}

resource "aws_security_group_rule" "egress_allow_all" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.this.id
}
