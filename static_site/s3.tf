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

resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.s3_bucket_sandbox.bucket
  key          = "index.html"
  source       = "${path.module}/index.html" # パス
  content_type = "text/html"
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
