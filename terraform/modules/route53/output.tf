output "alb_cert" {
    value = {
        arn = aws_acm_certificate.alb_cert.arn
        domain_name = aws_acm_certificate.alb_cert.domain_name
        status = aws_acm_certificate.alb_cert.status
    }
  
}

output "cloudfront_cert" {
    value = {
        arn = aws_acm_certificate.cloudfront_cert.arn
        domain_name = aws_acm_certificate.cloudfront_cert.domain_name
        status = aws_acm_certificate.cloudfront_cert.status
    }
}