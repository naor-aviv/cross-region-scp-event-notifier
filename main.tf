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

# Create Lambda
resource "aws_lambda_function" "lambda_function" {
  function_name = var.function_name
  description   = var.function_description
  runtime       = "python3.9"
  memory_size   = var.function_mem
  handler       = "${var.script_name}.lambda_handler"
  timeout       = var.function_timeout
  role          = aws_iam_role.lambda_role.arn
  s3_bucket     = module.lambda_s3_bucket.s3_bucket_id
  s3_key        = "${var.script_name}.zip"

  environment {
    variables = {
      for key, value in var.lambda_environment_variables : key => value
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "${var.function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule           = aws_cloudwatch_event_rule.all.name
  event_bus_name = aws_cloudwatch_event_bus.cross_account.name
  target_id      = "SendToLambda"
  arn            = aws_lambda_function.lambda_function.arn
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    actions   = ["logs:CreateLogStream", "logs:CreateLogGroup", "logs:PutLogEvents"]
    resources = [aws_cloudwatch_log_group.log_group.arn]
    effect = "Allow"
  }
  statement {
    actions   = ["ses:*"]
    resources = ["*"]
    effect = "Allow"
  }
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions   = ["sts:AssumeRole"]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "archive_file" "python_zip" {
  type        = "zip"
  source_file = "${var.script_name}.py"
  output_file_mode = "0666"
  output_path = "${var.script_name}.zip"
}

# Create Lambda log group
resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_group_retention
}

