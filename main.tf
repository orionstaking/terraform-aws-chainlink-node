locals {
  container_insights_monitoring = var.monitoring_enabled ? "enabled" : "disabled"

  node_config = flatten([
    for key, value in var.node_config : [{
      name  = key
      value = value
    }]
  ])
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
      docker_image      = "smartcontract/chainlink:${var.node_version}"
      aws_region        = var.aws_region
      port_ui           = var.chainlink_ui_port
      tls_port_ui       = var.tls_chainlink_ui_port
      port_node         = var.chainlink_node_port
      cpu               = var.task_cpu
      memory            = var.task_memory
      keystore_password = var.keystore_password_secret_arn
      api_credentials   = var.api_credentials_secret_arn
      database_url      = var.database_url_secret_arn
      tls_cert          = var.tls_cert_secret_arn
      tls_key           = var.tls_key_secret_arn
      tls_ui_enabled    = var.tls_ui_enabled && var.tls_type == "import" ? "true" : "false"
      node_config       = local.node_config
      subnet_mapping    = base64encode(jsonencode(var.subnet_mapping))
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
    container_port   = var.tls_ui_enabled && var.tls_type == "import" ? var.tls_chainlink_ui_port : var.chainlink_ui_port
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.node.arn
    container_name   = "${var.project}-${var.environment}-node"
    container_port   = var.chainlink_node_port
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
  type        = "ingress"
  from_port   = var.chainlink_node_port
  to_port     = var.chainlink_node_port
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.this.id
}

resource "aws_security_group_rule" "ingress_allow_ui" {
  type        = "ingress"
  from_port   = var.chainlink_ui_port
  to_port     = var.chainlink_ui_port
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
