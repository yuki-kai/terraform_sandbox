resource "aws_s3_bucket" "s3_bucket_sandbox" {
  bucket = "s3-sandbox-yuki-kai"
}

# S3のACLを無効化
resource "aws_s3_bucket_ownership_controls" "main" {
  bucket = aws_s3_bucket.s3_bucket_sandbox.id
  # バケットに格納されるすべてのオブジェクトの所有権を、バケットを所有するAWSアカウントに強制的に設定
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.s3_bucket_sandbox.id
  # パブリックアクセスをすべてブロック
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

locals {
  build_files = fileset("website/build", "**/*")
}

resource "aws_s3_object" "index_html" {
  bucket = aws_s3_bucket.s3_bucket_sandbox.bucket

  # filesetで取得したファイルパスのセットに対してループ
  for_each = local.build_files
  # S3オブジェクトのキー（パス）。S3上ではbuild/が不要なため、replaceで取り除く。
  key = replace(each.key, "build/", "")
  # ローカルファイルへの絶対パス
  source = "website/build/${each.key}"
  # ファイル内容の変更を検出してS3オブジェクトを更新するために必要
  etag = filemd5("website/build/${each.key}")
  # ファイルタイプ（Content-Type）を自動設定（例: text/html, application/javascriptなど）
  content_type = lookup(
    {
      "html" = "text/html",
      "css"  = "text/css",
      "js"   = "application/javascript",
      "json" = "application/json",
      "png"  = "image/png",
      "svg"  = "image/svg+xml",
      # 他の必要なMIMEタイプを追加
    },
    # ファイルの拡張子を取得
    regex(".*\\.([a-z]+)$", each.key)[0],
    "application/octet-stream" # 拡張子がない場合のデフォルト
  )

  depends_on = [aws_s3_bucket_policy.my_bucket_policy]
}

# S3 バケットポリシーの設定
resource "aws_s3_bucket_policy" "my_bucket_policy" {
  bucket = aws_s3_bucket.s3_bucket_sandbox.id
  policy = data.aws_iam_policy_document.s3_main_policy.json
}

data "aws_iam_policy_document" "s3_main_policy" {
  # CloudFront Distribution からのアクセスのみ許可
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.s3_bucket_sandbox.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudfront_distribution.s3_distribution.arn]
    }
  }
}

# API Gatewayのエンドポイントを取得するためのS3オブジェクト
resource "aws_s3_bucket" "api_gateway_endpoint_url" {
  bucket = "s3-sandbox-endpoint-url"
}

resource "aws_s3_object" "config_js" {
  bucket       = aws_s3_bucket.s3_bucket_sandbox.id
  key          = "config.js"
  content_type = "application/javascript"

  # Heredoc構文でJavaScriptコードを記述し、Terraform属性を補間
  content = <<-EOT
    const AppConfig = {
      API_ENDPOINT: "${var.apigateway_endpoint}"
    };
    
    // グローバルスコープに公開
    window.AppConfig = AppConfig; 
  EOT

  depends_on = [
    var.api_gateway_id,
    aws_s3_bucket_policy.my_bucket_policy,
  ]
  # metadata = {}
}
