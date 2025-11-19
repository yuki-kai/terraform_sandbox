variable "apigateway_endpoint" {
  description = "S3にデプロイされたサイトからAPI Gatewayのエンドポイントを参照する"
  type        = string
}
variable "api_gateway_id" {
  description = "階層ごとの依存関係を明示"
  type        = string
}
