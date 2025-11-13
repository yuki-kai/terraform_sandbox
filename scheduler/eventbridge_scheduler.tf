// Lambda role and policy
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

resource "aws_iam_role" "lambda_role" {
  name               = "scheduler-logger-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

// Package the function (source in ./function)
data "archive_file" "scheduler_lambda" {
  type        = "zip"
  source_file = "./function/index.js"
  output_path = "./function/output.zip"
}

resource "aws_lambda_function" "scheduler_logger" {
  function_name    = "scheduler_logger"
  filename         = data.archive_file.scheduler_lambda.output_path
  source_code_hash = data.archive_file.scheduler_lambda.output_base64sha256
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs22.x"
}

# テスト用
resource "aws_lambda_function" "second" {
  function_name    = "second"
  filename         = data.archive_file.scheduler_lambda.output_path
  source_code_hash = data.archive_file.scheduler_lambda.output_base64sha256
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.second_handler"
  runtime          = "nodejs22.x"
}

output "second" {
  description = "test"
  value = aws_lambda_function.second.arn
}

// Role that Scheduler will assume to invoke Lambda
resource "aws_iam_role" "scheduler_invoke_role" {
  name = "scheduler-invoke-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "scheduler.amazonaws.com" },
        Action    = "sts:AssumeRole",
      }
    ]
  })
}

resource "aws_iam_role_policy" "scheduler_invoke_policy" {
  name = "scheduler-invoke-lambda"
  role = aws_iam_role.scheduler_invoke_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["lambda:InvokeFunction"],
        Resource = aws_lambda_function.scheduler_logger.arn
      }
    ]
  })
}

// Optional: explicit permission on Lambda (not strictly required when Scheduler assumes role,
// but harmless to include)
resource "aws_lambda_permission" "allow_scheduler" {
  statement_id  = "AllowSchedulerInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scheduler_logger.function_name
  principal     = "scheduler.amazonaws.com"
}

resource "aws_scheduler_schedule" "every_10_minutes" {
  name                         = "invoke-scheduler-logger-every-10-mins"
  description                  = "Invoke scheduler_logger every 10 minutes"
  schedule_expression_timezone = "Asia/Tokyo"
  # MEMO: at(2025-11-13T08:46:00)みたいな書き方で1回実行も可能
  schedule_expression          = "rate(10 minutes)"
  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.scheduler_logger.arn
    role_arn = aws_iam_role.scheduler_invoke_role.arn
  }

  state = "ENABLED"
}
