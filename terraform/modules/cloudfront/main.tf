resource "aws_cloudfront_origin_access_identity" "cf" {
  comment = "OAI"
}

resource "aws_cloudfront_distribution" "CloudFrontDistributionfrontend" {
  aliases = [
    "crm.${var.domain}"
  ]

  origin {
    domain_name = "crm-frontend.${var.domain}.s3.amazonaws.com"
    origin_id   = "S3-crm-frontend.${var.domain}"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cf.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = ""
  price_class         = "PriceClass_100"
  default_root_object = "index.html"
  http_version        = "http2"

  default_cache_behavior {
  response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id

  allowed_methods        = ["HEAD", "GET", "OPTIONS"]
  cached_methods         = ["GET", "HEAD"]
  target_origin_id       = "S3-crm-frontend.${var.domain}"
  viewer_protocol_policy = "redirect-to-https"
  compress               = true
  smooth_streaming       = false

  cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"


}

  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 403
    response_code         = "200"
    response_page_path    = "/index.html"
  }

  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 404
    response_code         = "200"
    response_page_path    = "/index.html"
  }

  viewer_certificate {
    acm_certificate_arn            = var.cloudfront_cert
    cloudfront_default_certificate = false
    minimum_protocol_version       = "TLSv1.2_2018"
    ssl_support_method             = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}


resource "aws_cloudfront_distribution" "CloudFrontDistributionOnboarding" {
    aliases = [
        "onboarding.${var.domain}"
    ]
    origin {
        domain_name = "onboarding.${var.domain}.s3.ap-south-1.amazonaws.com"
        origin_id = "onboarding.${var.domain}"
         s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cf.cloudfront_access_identity_path
    }
 
    }
    default_cache_behavior {
        response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id

        allowed_methods = [
            "HEAD",
            "GET",
            "OPTIONS"
        ]

        compress = true
        smooth_streaming  = false
        target_origin_id = "onboarding.${var.domain}"
        viewer_protocol_policy = "redirect-to-https"
        cached_methods = ["GET", "HEAD"]
        cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    }
    custom_error_response {
        error_caching_min_ttl = 0
        error_code = 403
        response_code = "200"
        response_page_path = "/index.html"
    }
    custom_error_response {
        error_caching_min_ttl = 0
        error_code = 404
        response_code = "200"
        response_page_path = "/index.html"
    }
    comment = ""
    price_class = "PriceClass_100"
    enabled = true
    viewer_certificate {
        acm_certificate_arn = var.cloudfront_cert
        cloudfront_default_certificate = false
        minimum_protocol_version = "TLSv1.2_2021"
        ssl_support_method = "sni-only"
    }
    restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }
    http_version = "http2"
    is_ipv6_enabled = true
}



#response headers

resource "aws_cloudfront_response_headers_policy" "security_headers" {
  name = "security-headers-policy"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 60
      include_subdomains         = true
      override                   = true
    }

    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    content_security_policy {
      content_security_policy = "default-src 'none'; script-src 'self'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; style-src-elem 'self' 'unsafe-inline' https://fonts.googleapis.com; img-src 'self' data:; font-src 'self' https://fonts.gstatic.com https://cdn.jsdelivr.net; connect-src https://*.${var.domain}; upgrade-insecure-requests; manifest-src 'self'; prefetch-src 'self'; media-src 'self'"
      override                = true
    }
  }

  custom_headers_config {
    items {
      header   = "X-Permitted-Cross-Domain-Policies"
      value    = "none"
      override = true
    }
  }
}