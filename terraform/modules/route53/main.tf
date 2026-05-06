
resource "aws_route53_zone" "private_zone" {
  name = var.domain
  vpc {
    vpc_id = var.vpc_id
  }
  
}

resource "aws_route53_zone" "public_zone" {
  name = var.domain
}





resource "aws_route53_record" "crm-frontend" {
  zone_id = aws_route53_zone.public_zone.zone_id
  name    = "crm.${var.domain}"
  type    = "CNAME"
  ttl     = "300"
  records = [var.cfd_frontend_domain_name] 
  
}

resource "aws_route53_record" "onboarding" {
  zone_id = aws_route53_zone.public_zone.zone_id
  name    = "onboarding.${var.domain}"
  type    = "CNAME"
  ttl     = "300"
  records = [var.cfd_onboarding_domain_name] 
}
resource "aws_route53_record" "argocd" {
  zone_id = aws_route53_zone.public_zone.zone_id
  name    = "argocd.${var.domain}"
  type    = "CNAME"
  ttl     = "300"
  records = ["k8s-argocd-argocdin-494295b80d-2039609855.us-east-1.elb.amazonaws.com"] 
}

resource "aws_route53_record" "backend" {
  zone_id = aws_route53_zone.public_zone.zone_id
  name    = "apis.${var.domain}"
  type    = "CNAME"
  ttl     = "300"
  records = ["k8s-argocd-argocdin-494295b80d-2039609855.us-east-1.elb.amazonaws.com"] 
}

resource "aws_route53_record" "grafana" {
  zone_id = aws_route53_zone.public_zone.zone_id
  name    = "grafana.${var.domain}"
  type    = "CNAME"
  ttl     = "300"
  records = ["k8s-argocd-argocdin-494295b80d-2039609855.us-east-1.elb.amazonaws.com"] 
}
resource "aws_cloudwatch_log_group" "LogsLogGroup" {
    name = "celery-worker-task-log-group"
    retention_in_days = 90
}

resource "aws_cloudwatch_log_group" "LogsLogGroup2" {
    name = "payout-refund-worker-log-group"
    retention_in_days = 90
}

resource "aws_cloudwatch_log_group" "LogsLogGroup3" {
    name = "payout-status-enquiry-worker-log-group"
    retention_in_days = 90
}

resource "aws_cloudwatch_log_group" "LogsLogGroup4" {
    name = "webhook-worker-log-group"
    retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "LogsLogGroup5" {
    name = "crm-eks-log-group"
}

####################################################




# ── Certificate for CloudFront (MUST be us-east-1) ──
resource "aws_acm_certificate" "cloudfront_cert" {
  provider          = aws.us_east_1         # CloudFront only accepts us-east-1
  domain_name       = var.domain
  subject_alternative_names = ["*.${var.domain}"] # covers www, api, etc.
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# ── Certificate for ALB (your region, e.g. us-east-1) ──
resource "aws_acm_certificate" "alb_cert" {
  domain_name       = var.domain
  subject_alternative_names = ["*.${var.domain}"]
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}



# ── Validation records for CloudFront cert ──
resource "aws_route53_record" "cloudfront_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cloudfront_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  zone_id = aws_route53_zone.public_zone.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

# ── Validation records for ALB cert ──
resource "aws_route53_record" "alb_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.alb_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  zone_id = aws_route53_zone.public_zone.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

# ── Wait for validation to complete ──
resource "aws_acm_certificate_validation" "cloudfront_cert" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cloudfront_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cloudfront_cert_validation : record.fqdn]
}

resource "aws_acm_certificate_validation" "alb_cert" {
  certificate_arn         = aws_acm_certificate.alb_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.alb_cert_validation : record.fqdn]
}

