# API Gatewayからのリクエストを受け、EventBridgeスケジューラを登録するLambda関数
resource "aws_lambda_function" "request_schedule" {
  function_name    = "requestSchedule"
  filename         = data.archive_file.sandbox.output_path
  role             = aws_iam_role.lambda_role.arn
  source_code_hash = data.archive_file.sandbox.output_base64sha256
  runtime          = "nodejs22.x"
  handler          = "requestSchedule.handler"
  environment {
    variables = {
      TARGET_LAMBDA_ARN  = aws_lambda_function.request_ses.arn
      SCHEDULER_ROLE_ARN = aws_iam_role.scheduler_invoke_lambda_role.arn
    }
  }
}

data "archive_file" "sandbox" {
  type        = "zip"
  source_dir  = "./function/dist"
  output_path = "./function/dist/output.zip"
}

# EventBridgeスケジューラが実行するLambda関数
resource "aws_lambda_function" "request_ses" {
  function_name    = "requestSes"
  filename         = data.archive_file.sandbox.output_path
  role             = aws_iam_role.lambda_role.arn
  source_code_hash = data.archive_file.sandbox.output_base64sha256
  runtime          = "nodejs22.x"
  handler          = "requestSes.handler"
}
