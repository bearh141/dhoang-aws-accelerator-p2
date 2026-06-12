resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${local.name}-high-cpu"
  alarm_description   = "Send email alert when EC2 CPU is greater than ${var.cpu_alarm_threshold}%."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.cpu_alarm_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.cpu_alarm_period
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.monitoring_target.id
  }

  alarm_actions = [aws_sns_topic.cpu_alarm.arn]
  ok_actions    = [aws_sns_topic.cpu_alarm.arn]

  tags = local.tags
}

