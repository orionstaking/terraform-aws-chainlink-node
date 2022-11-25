# ECS execution role with access to ECR and Cloudwatch
data "aws_iam_policy_document" "this" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]
    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "kms:Decrypt"
    ]
    resources = [
      var.keystore_password_secret_arn,
      var.api_credentials_secret_arn,
      var.database_url_secret_arn
    ]
  }

  dynamic "statement" {
    for_each = var.tls_ui_enabled && var.tls_type == "import" ? ["tls"] : [] 

    content {
      effect = "Allow"
      actions = [
        "secretsmanager:GetSecretValue",
        "kms:Decrypt"
      ]
      resources = [
        var.tls_cert_secret_arn,
        var.tls_key_secret_arn
      ]
    }
  }
}

resource "aws_iam_policy" "this" {
  name        = "${var.project}-${var.environment}-node-task-exec-policy"
  description = "Provides access to ECR and Cloudwatch logs"
  policy      = data.aws_iam_policy_document.this.json
}

resource "aws_iam_role" "this" {
  name = "${var.project}-${var.environment}-node-ecs-tasks"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "this" {
  policy_arn = aws_iam_policy.this.arn
  role       = aws_iam_role.this.name
}
