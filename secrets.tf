resource "aws_secretsmanager_secret" "config" {
  name        = "${var.project}/${var.environment}/node/config"
  description = "TOML config for ${var.project}-${var.environment} in base64 format"
  
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "config" {
  secret_id     = aws_secretsmanager_secret.config.id
  secret_string = filebase64("config.toml")
}
