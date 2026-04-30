terraform {
  backend "s3" {
     bucket         = "frenzofunz-tfstate"    # S3 bucket name
     key            = "prod/terraform.tfstate" # path inside bucket
     region         = "ap-south-1"
     encrypt        = true
     use_lockfile = false
  }
}
