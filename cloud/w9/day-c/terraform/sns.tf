resource "aws_sns_topic" "cpu_alarm" {
  name = "${local.name}-cpu-alarm-topic"

  tags = local.tags
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.cpu_alarm.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

