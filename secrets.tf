resource "aws_secretsmanager_secret" "config" {
  name        = "${var.project}/${var.environment}/node/config"
  description = "TOML config for ${var.project}-${var.environment} in base64 format"
  
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "config" {
  secret_id     = aws_secretsmanager_secret.config.id
  secret_string = filebase64("config.toml")
}

resource "aws_secretsmanager_secret" "secrets" {
  name        = "${var.project}/${var.environment}/node/secrets"
  description = "TOML secrets for ${var.project}-${var.environment} in base64 format"

  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "secrets" {
  secret_id     = aws_secretsmanager_secret.secrets.id
  secret_string = filebase64("secrets.toml")
}
