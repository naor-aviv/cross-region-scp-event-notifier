resource "aws_cloudwatch_event_bus" "cross_account" {
  name = "CrossAccountDestinationBus"
}

data "aws_iam_policy_document" "cross_account" {
  statement {
    sid    = "allow_all_accounts_from_organization_to_put_events"
    effect = "Allow"
    actions = [
      "events:PutEvents",
    ]
    resources = [aws_cloudwatch_event_bus.cross_account.arn]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = [data.aws_organizations_organization.current.id]
    }
  }
}

resource "aws_cloudwatch_event_bus_policy" "cross_account" {
  policy         = data.aws_iam_policy_document.cross_account.json
  event_bus_name = aws_cloudwatch_event_bus.cross_account.name
}

resource "aws_cloudwatch_event_rule" "all" {
  name           = var.project_name
  description    = "Capture all events and send them to SNS topic"
  event_bus_name = aws_cloudwatch_event_bus.cross_account.name

  event_pattern = jsonencode({
    source = [{ prefix = "" }] # Match all events
  })
}

resource "aws_cloudwatch_event_target" "sns" {
  rule           = aws_cloudwatch_event_rule.all.name
  event_bus_name = aws_cloudwatch_event_bus.cross_account.name
  target_id      = "SendToSNS"
  arn            = aws_sns_topic.this.arn
}

resource "aws_sns_topic" "this" {
  name = var.project_name
}

resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.this.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [aws_sns_topic.this.arn]
  }
}

resource "aws_sns_topic_subscription" "email" {
  for_each = toset(var.email_recipients)

  topic_arn = aws_sns_topic.this.arn
  protocol  = "email"
  endpoint  = each.key
}