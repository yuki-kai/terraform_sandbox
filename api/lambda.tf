resource "aws_lambda_function" "sandbox_lambda_function" {
  function_name    = "sandbox_lambda_function_typescript"
  filename         = data.archive_file.sandbox.output_path
  role             = aws_iam_role.lambda_role.arn
  source_code_hash = data.archive_file.sandbox.output_base64sha256
  runtime          = "nodejs22.x"
  handler          = "index.handler"
}

data "archive_file" "sandbox" {
  type        = "zip"
  source_dir  = "./function/dist"
  output_path = "./function/output.zip"
}

resource "aws_api_gateway_rest_api" "api" {
  name = "sandbox-api"
}

resource "aws_api_gateway_resource" "resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "test"
}

resource "aws_api_gateway_method" "sandbox" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "sandbox" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.sandbox.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.sandbox_lambda_function.invoke_arn
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sandbox_lambda_function.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
}

resource "aws_api_gateway_deployment" "sandbox" {
  depends_on = [aws_api_gateway_integration.sandbox, aws_lambda_permission.api_gateway]

  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_stage" "stage" {
  stage_name    = "stage"
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.sandbox.id
}
