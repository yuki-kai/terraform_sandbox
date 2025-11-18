# LambdaにアタッチするIAM Role
resource "aws_iam_role" "lambda_role" {
  name               = "sandbox-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_passrole_policy_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_passrole_policy.arn
}
resource "aws_iam_policy" "lambda_passrole_policy" {
  name = "lambda-passrole-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["iam:PassRole"],
        Resource = aws_iam_role.scheduler_invoke_lambda_role.arn
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role_policy" "lambda_create_scheduler_policy" {
  name = "lambda-create-scheduler-policy"
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "lambda:InvokeFunction",
          "scheduler:CreateSchedule",
          "scheduler:GetSchedule",
          "scheduler:DeleteSchedule"
        ],
        Resource = "arn:aws:scheduler:ap-northeast-1:${data.aws_caller_identity.current.account_id}:schedule/*"
      }
    ]
  })
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# API GatewayにアタッチするIAM Role
resource "aws_iam_role" "api_gateway_role" {
  name               = "sandbox-apigateway-role"
  assume_role_policy = data.aws_iam_policy_document.api_gateway_assume_role.json
}

resource "aws_iam_role_policy_attachment" "api_gateway_policy_logs" {
  role       = aws_iam_role.api_gateway_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_iam_role_policy_attachment" "api_gateway_policy_lambda" {
  role       = aws_iam_role.api_gateway_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
}

data "aws_iam_policy_document" "api_gateway_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

# EventBridgeがLambdaをコールするためのロール
resource "aws_iam_role" "scheduler_invoke_lambda_role" {
  name = "scheduler-invoke-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "scheduler.amazonaws.com" }, # ← EventBridge Scheduler用
        Action    = "sts:AssumeRole",
      }
    ]
  })
}

resource "aws_iam_role_policy" "scheduler_invoke_policy" {
  name = "scheduler-invoke-lambda"
  role = aws_iam_role.scheduler_invoke_lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["lambda:InvokeFunction"],
        Resource = aws_lambda_function.request_ses.arn
      }
    ]
  })
}

resource "aws_iam_role" "ses_access_lambda_role" {
  name               = "ses-request-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_policy" "ses_access_policy" {
  name   = "ses-access-policy"
  policy = data.aws_iam_policy_document.lambda_ses_access_role.json
}

data "aws_iam_policy_document" "lambda_ses_access_role" {
  statement {
    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail",
    ]
    resources = ["arn:aws:ses:ap-northeast-1:${data.aws_caller_identity.current.account_id}:identity/*"]
  }
}

resource "aws_iam_role_policy_attachment" "ses_access_attachment" {
  role       = aws_iam_role.ses_access_lambda_role.name
  policy_arn = aws_iam_policy.ses_access_policy.arn
}
