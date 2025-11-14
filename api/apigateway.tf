resource "aws_api_gateway_rest_api" "api" {
  name = "sandbox-api"
}

resource "aws_api_gateway_resource" "resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "sandbox"
}

resource "aws_api_gateway_method" "sandbox" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# API Gatewayで受け取ったリクエストをバックエンドのデータ変換と統合
resource "aws_api_gateway_integration" "sandbox" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.sandbox.http_method

  # API GatewayのメソッドリクエストのHTTPメソッドに関係なく統合リクエストにはPOST
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.sandbox_lambda_function.invoke_arn
}

# API GatewayがLambdaを呼び出すための許可
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sandbox_lambda_function.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*"
}

resource "aws_api_gateway_deployment" "sandbox" {
  depends_on  = [aws_api_gateway_integration.sandbox, aws_lambda_permission.api_gateway]
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_stage" "v1" {
  stage_name    = "v1"
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.sandbox.id

  # access_log_settingsでログ出力可能
}
