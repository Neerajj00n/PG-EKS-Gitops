terraform {
  backend "s3" {
     bucket         = "frenzofun-tfstate-file"    # S3 bucket name
     key            = "prod/terraform.tfstate" # path inside bucket
     region         = "us-east-1"
     encrypt        = true
     use_lockfile = true
  }
}
