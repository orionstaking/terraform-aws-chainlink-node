resource "aws_secretsmanager_secret" "config" {
  name                    = "${var.project}/${var.environment}/node/config"
  description             = "TOML config for ${var.project}-${var.environment} in base64 format"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "config" {
  secret_id     = aws_secretsmanager_secret.config.id
  secret_string = var.config_toml
}

resource "aws_secretsmanager_secret" "otel_config" {
  name                    = "${var.project}-${var.environment}/node/otel-config"
  description             = "OpenTelemetry collector configuration for ${var.project}-${var.environment} node in base64 format"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "otel_config" {
  secret_id     = aws_secretsmanager_secret.otel_config.id
  secret_string = var.otel_config
}
