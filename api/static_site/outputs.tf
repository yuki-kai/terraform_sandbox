output "cloudfront_url" {
  description = "WebサイトのURL"
  value       = "https://${aws_cloudfront_distribution.s3_distribution.domain_name}"
}
