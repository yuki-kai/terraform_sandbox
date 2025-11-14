# API Gatewayからのリクエストを受け、EventBridgeスケジューラを登録するLambda関数
resource "aws_lambda_function" "sandbox_lambda_function" {
  function_name    = "sandbox_lambda_function_typescript"
  filename         = data.archive_file.sandbox.output_path
  role             = aws_iam_role.lambda_role.arn
  source_code_hash = data.archive_file.sandbox.output_base64sha256
  runtime          = "nodejs22.x"
  handler          = "index.handler"
  environment {
    variables = {
      TARGET_LAMBDA_ARN  = aws_lambda_function.sandbox_lambda_function_2.arn
      SCHEDULER_ROLE_ARN = aws_iam_role.scheduler_invoke_lambda_role.arn
    }
  }
}

data "archive_file" "sandbox" {
  type        = "zip"
  source_dir  = "./function/dist"
  output_path = "./function/output.zip"
}

# EventBridgeスケジューラが実行するLambda関数
resource "aws_lambda_function" "sandbox_lambda_function_2" {
  function_name    = "sandbox_lambda_function_typescript_2"
  filename         = data.archive_file.sandbox.output_path
  role             = aws_iam_role.lambda_role.arn
  source_code_hash = data.archive_file.sandbox.output_base64sha256
  runtime          = "nodejs22.x"
  handler          = "index.second_handler"
}
