resource "aws_sns_topic" "alerts" {
  name = "self-healing-infra-alerts"

  tags = {
    Name = "self-healing-infra-alerts"
  }
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "self-healing-asg-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  alarm_description = "Triggers when average CPU across the ASG is >= 80% for 10 minutes"
  alarm_actions     = [aws_sns_topic.alerts.arn]
  ok_actions        = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "self-healing-asg-high-cpu"
  }
}
