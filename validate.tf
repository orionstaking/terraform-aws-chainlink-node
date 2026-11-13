locals {
  validate_command = "mkdir -p ~/chainlink && printf '%s' \"$CONFIG\" > ~/chainlink/config.toml && printf '%s' \"$SECRETS\" > ~/chainlink/secrets.toml && chainlink --config ~/chainlink/config.toml --secrets ~/chainlink/secrets.toml node validate >/dev/null && echo Valid configuration."
}

resource "aws_ecs_task_definition" "validate" {

  family                   = "${var.project}-${var.environment}-node-validate"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.this.arn

  container_definitions = jsonencode([
    {
      name       = "${var.project}-${var.environment}-node-validate"
      image      = "${var.node_image_source}:${var.node_version}"
      essential  = true
      cpu        = 1024
      memory     = 2048
      entryPoint = ["/bin/bash"]
      command    = ["-c", local.validate_command]
      secrets = [
        {
          name      = "CONFIG"
          valueFrom = var.config_plain_secret_arn
        },
        {
          name      = "SECRETS"
          valueFrom = var.secrets_plain_secret_arn
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = var.aws_region
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-stream-prefix = "validate"
        }
      }
    }
  ])
}
