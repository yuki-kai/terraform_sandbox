terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  required_version = ">= 1.2"
}

provider "aws" {
  region = "ap-northeast-1"
}

module "static_site" {
  source = "./static_site"

  # ルートディレクトリから見て階層の深いtfファイルに値を渡す
  apigateway_endpoint = "${aws_api_gateway_stage.v1.invoke_url}/${aws_api_gateway_resource.resource.path_part}"
  api_gateway_id      = aws_api_gateway_deployment.sandbox.id
}

output "website_url" {
  description = "WebサイトのURL"
  value       = module.static_site.cloudfront_url
}
