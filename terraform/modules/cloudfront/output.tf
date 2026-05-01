output "cfd_frontend_domain_name" {
    value = aws_cloudfront_distribution.CloudFrontDistributionfrontend.domain_name
  
}
output "cfd_frontend_arn" {
    value = aws_cloudfront_origin_access_identity.cf.iam_arn
  
}
output "cfd_onboarding_domain_name" {
    value = aws_cloudfront_distribution.CloudFrontDistributionOnboarding.domain_name
}
output "cfd_onboarding_arn" {
    value = aws_cloudfront_origin_access_identity.cf.iam_arn
}