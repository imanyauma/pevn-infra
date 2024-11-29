output "s3_web_domain" {
  value = aws_s3_bucket_website_configuration.pevn_frontend.website_domain
}

output "s3_name" {
  value = aws_s3_bucket.pevn_frontend.bucket
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.pevn_frontend.domain_name
}