locals {
  log_errors = [
    {
      name    = "ErrorNodeUnreachable"
      pattern = "{ $.nodeState = \"Unreachable\" || $.msg = \"*node is dead*\" }"
      level   = "Error"
      comment = "[ERROR] Failed to connect to one of the specified RPC node"
      period  = "180"
    },
    {
      name    = "ErrorUnknown"
      pattern = "{ $.level = \"error\" && $.nodeState != \"Unreachable\" && $.msg != \"*node is dead*\" }"
      level   = "Error"
      comment = "[ERROR] Unknown issue. Please check AWS CLoudWatch logs. More abount log levels: https://docs.chain.link/docs/configuration-variables/#log_level"
      period  = "60"
    },
    {
      name    = "CritTimeoutSQL"
      pattern = "{ $.msg = \"*SLOW SQL QUERY*\" }"
      level   = "Crit"
      comment = "[CRIT] SQL queries constantly timed out"
      period  = "180"
    },
    {
      name    = "CritUnknown"
      pattern = "{ $.level = \"crit\" && $.msg != \"*SLOW SQL QUERY*\" }"
      level   = "Crit"
      comment = "[CRIT] Unknown issue. Please check AWS CLoudWatch logs. More abount log levels: https://docs.chain.link/docs/configuration-variables/#log_level"
      period  = "60"
    },
    {
      name    = "PanicUnknown"
      pattern = "{ $.level = \"panic\" }"
      level   = "panic"
      comment = "[PANIC] Unknown issue. Please check AWS CLoudWatch logs. More abount log levels: https://docs.chain.link/docs/configuration-variables/#log_level"
      period  = "60"
    },
    {
      name    = "FatalUnknown"
      pattern = "{ $.level = \"fatal\" }"
      level   = "Fatal"
      comment = "[FATAL] Unknown issue. Please check AWS CLoudWatch logs. More abount log levels: https://docs.chain.link/docs/configuration-variables/#log_level"
      period  = "60"
    }
  ]
}

# SNS topic for alerts if custom not specified
resource "aws_sns_topic" "this" {
  count = var.monitoring_enabled && var.sns_topic_arn == "" ? 1 : 0

  name = "${var.project}-${var.environment}-node"
}

# Log errors to Metrics transformation
resource "aws_cloudwatch_log_metric_filter" "error_node_unreachable" {
  for_each = { for log_error in local.log_errors : log_error.name => log_error if var.monitoring_enabled }

  name           = "${var.project}-${var.environment}-node-${each.value.name}"
  pattern        = each.value.pattern
  log_group_name = aws_cloudwatch_log_group.this.name

  metric_transformation {
    name          = "${var.project}-${var.environment}-node-${each.value.name}"
    namespace     = "${var.project}-${var.environment}-node-log-errors"
    value         = "1"
    default_value = "0"
  }
}

# Alarms based on logs
resource "aws_cloudwatch_metric_alarm" "log_alarms" {
  for_each = { for log_error in local.log_errors : log_error.name => log_error if var.monitoring_enabled }

  alarm_name          = "${var.project}-${var.environment}-node-${each.value.name}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "${var.project}-${var.environment}-node-${each.value.name}"
  namespace           = "${var.project}-${var.environment}-node-log-errors"
  period              = each.value.period
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = each.value.comment
  actions_enabled     = "true"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.sns_topic_arn == "" ? [aws_sns_topic.this[0].arn] : [var.sns_topic_arn]
  ok_actions          = var.sns_topic_arn == "" ? [aws_sns_topic.this[0].arn] : [var.sns_topic_arn]
}

# Resource utilization alarms
resource "aws_cloudwatch_metric_alarm" "memory_utilization" {
  count = var.monitoring_enabled ? 1 : 0

  alarm_name          = "${var.project}-${var.environment}-node-MemoryUtilizationHigh"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  threshold           = "80"
  alarm_description   = "Memory utilization has exceeded 80%"
  actions_enabled     = "true"
  alarm_actions       = var.sns_topic_arn == "" ? [aws_sns_topic.this[0].arn] : [var.sns_topic_arn]
  ok_actions          = var.sns_topic_arn == "" ? [aws_sns_topic.this[0].arn] : [var.sns_topic_arn]

  metric_query {
    id          = "e1"
    expression  = "m2*100/m1"
    label       = "Memory utilization"
    return_data = "true"
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "MemoryReserved"
      namespace   = "ECS/ContainerInsights"
      period      = "60"
      stat        = "Average"

      dimensions = {
        ClusterName = "${var.project}-${var.environment}-node"
        ServiceName = "${var.project}-${var.environment}-node"
      }
    }
  }

  metric_query {
    id = "m2"

    metric {
      metric_name = "MemoryUtilized"
      namespace   = "ECS/ContainerInsights"
      period      = "60"
      stat        = "Average"

      dimensions = {
        ClusterName = "${var.project}-${var.environment}-node"
        ServiceName = "${var.project}-${var.environment}-node"
      }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  count = var.monitoring_enabled ? 1 : 0

  alarm_name          = "${var.project}-${var.environment}-node-CPUUtilizationHigh"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  threshold           = "80"
  alarm_description   = "CPU utilization has exceeded 80%"
  actions_enabled     = "true"
  alarm_actions       = var.sns_topic_arn == "" ? [aws_sns_topic.this[0].arn] : [var.sns_topic_arn]
  ok_actions          = var.sns_topic_arn == "" ? [aws_sns_topic.this[0].arn] : [var.sns_topic_arn]

  metric_query {
    id          = "e1"
    expression  = "m2*100/m1"
    label       = "CPU utilization"
    return_data = "true"
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "CpuReserved"
      namespace   = "ECS/ContainerInsights"
      period      = "60"
      stat        = "Average"

      dimensions = {
        ClusterName = "${var.project}-${var.environment}-node"
        ServiceName = "${var.project}-${var.environment}-node"
      }
    }
  }

  metric_query {
    id = "m2"

    metric {
      metric_name = "CpuUtilized"
      namespace   = "ECS/ContainerInsights"
      period      = "60"
      stat        = "Average"

      dimensions = {
        ClusterName = "${var.project}-${var.environment}-node"
        ServiceName = "${var.project}-${var.environment}-node"
      }
    }
  }
}

resource "aws_cloudwatch_dashboard" "this" {
  count = var.monitoring_enabled ? 1 : 0

  dashboard_name = "${var.project}-${var.environment}-node"
  dashboard_body = templatefile(
    "${path.module}/templates/cw_dashboard.json.tpl",
    {
      project        = var.project
      environment    = var.environment
      region         = var.aws_region
      account_id     = var.aws_account_id
      log_group_name = aws_cloudwatch_log_group.this.name
    }
  )
}
