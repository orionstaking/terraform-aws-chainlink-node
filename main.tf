locals {
  container_insights_monitoring = var.monitoring_enabled ? "enabled" : "disabled"

  env_vars = flatten([
    for key, value in var.env_vars : [{
      name  = key
      value = value
    }]
  ])

  tf_announce_ips = [
    for subnet in var.subnet_mapping: subnet.ip
  ]
}

# TOML config parse
data "external" "parse_config" {
  program = ["python3","${path.module}/parse_config.py"]
  query = {
    tf_announce_ips = join(",", local.tf_announce_ips)
  }
}

locals {
  ui_port = data.external.parse_config.result.http_port
  tls_import = data.external.parse_config.result.tls_import
  tls_ui_port = data.external.parse_config.result.https_port
  tls_cert_path = data.external.parse_config.result.cert_path
  tls_cert_key = data.external.parse_config.result.key_path
  networking_stack = data.external.parse_config.result.networking_stack
  announce_port_v1 = data.external.parse_config.result.announce_port
  listen_port_v1 = data.external.parse_config.result.listen_port
  announce_port_v2 = element(split(":", element(split(",", data.external.parse_config.result.announce_addresses), 0)), 1)
  listen_port_v2 = element(split(":", data.external.parse_config.result.listen_addresses), 1)
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
      project           = var.project
      environment       = var.environment
      docker_image      = "${var.node_image_source}:${var.node_version}"
      aws_region        = var.aws_region
      ui_port           = local.ui_port
      tls_ui_port       = local.tls_ui_port
      tls_ui_enabled    = local.tls_import
      networking_stack  = local.networking_stack
      announce_port_v1  = local.announce_port_v1
      listen_port_v1    = local.listen_port_v1
      announce_port_v2  = local.announce_port_v2
      listen_port_v2    = local.listen_port_v2
      task_cpu          = var.task_cpu
      task_memory       = var.task_memory
      tls_cert          = var.tls_cert_secret_arn
      tls_key           = var.tls_key_secret_arn
      env_vars          = local.env_vars
      config            = aws_secretsmanager_secret.config.arn
      secrets           = var.secrets_secret_arn
      init_script       = replace(file("${path.module}/templates/init_script.sh.tpl"), "\n", " && ")
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
    container_port   = local.tls_import ? local.tls_ui_port : local.ui_port
  }

  dynamic "load_balancer" {
    for_each = local.networking_stack == "V1" || local.networking_stack == "V1V2" ? ["V1"] : []

    content {
      target_group_arn = aws_lb_target_group.node[0].arn
      container_name   = "${var.project}-${var.environment}-node"
      container_port   = local.listen_port_v1
    }
  }

  dynamic "load_balancer" {
    for_each = local.networking_stack == "V1V2" || local.networking_stack == "V2" ? ["V2"] : []

    content {
      target_group_arn = aws_lb_target_group.node_v2[0].arn
      container_name   = "${var.project}-${var.environment}-node"
      container_port   = local.listen_port_v2
    }
  }
}

# Log groups to store logs from Node
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/ecs/${var.project}-${var.environment}-node"
  retention_in_days = 7
}

# SG for ECS Tasks
resource "aws_security_group" "this" {
  name        = "${var.project}-${var.environment}-node-ecs-tasks"
  description = "Allow trafic between alb and Chainlink Node"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "ingress_allow_node" {
  count = local.networking_stack == "V1" || local.networking_stack == "V1V2" ? 1 : 0

  type        = "ingress"
  from_port   = local.announce_port_v1
  to_port     = local.announce_port_v1
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.this.id
}

resource "aws_security_group_rule" "ingress_allow_node_v2" {
  count = local.networking_stack == "V1V2" || local.networking_stack == "V2" ? 1 : 0

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
  cidr_blocks = [var.vpc_cidr_block]

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
