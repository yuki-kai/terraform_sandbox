resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.s3_bucket_sandbox.bucket_regional_domain_name
    origin_id                = "S3-my-cloudfront-bucket"
    origin_access_control_id = aws_cloudfront_origin_access_control.main.id
  }

  enabled             = true # ディストリビューションを有効化
  is_ipv6_enabled     = true # IPv6 を有効化
  comment             = "CloudFront Distribution for S3 bucket in Tokyo region"
  default_root_object = "index.html" # ルートにアクセスした際のデフォルトファイル

  # デフォルトのキャッシュ動作設定（GET/HEAD のみ許可し、HTTPS にリダイレクト）
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-my-cloudfront-bucket"

    forwarded_values {
      query_string = false # クエリパラメータをキャッシュのキーに含めない

      cookies {
        forward = "none" # クッキーを転送しない
      }
    }

    viewer_protocol_policy = "redirect-to-https" # HTTP を HTTPS にリダイレクト
  }

  # 地理的制限の設定（制限なし）
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # 料金クラスの設定（安価なリージョンのみ使用）
  price_class = "PriceClass_100"

  # CloudFront の SSL 証明書設定（デフォルトの CloudFront 証明書を使用）
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "MyCloudFrontDistribution"
  }
}

// OAC
resource "aws_cloudfront_origin_access_control" "main" {
  name                              = "cf-oac-with-tf-example"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
