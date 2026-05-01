terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.24"

    }
    random = {                    # add this
      source  = "hashicorp/random"
      version = "~> 3.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "ap-south-1"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.project_name
  cidr = "10.0.0.0/16"

  azs             = ["ap-south-1a", "ap-south-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = false   
  enable_dns_hostnames   = true
  enable_dns_support     = true

  # Required tags for EKS to discover subnets
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"      = "1"
    "kubernetes.io/cluster/${var.project_name}-eks-cluster"    = "shared"
  }
  public_subnet_tags = {
    "kubernetes.io/role/elb"               = "1"
    "kubernetes.io/cluster/${var.project_name}-eks-cluster"    = "shared"
  }
}

module "eks" {
  source  = "../../modules/eks"
  project_name     = var.project_name
  vpc_id           = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets
  public_access_cidrs = ["0.0.0.0/0"]
  cluster_version  = "1.31"
  eks_role_arn    = module.iam.cluster_role_arn
  node_group_role_arn = module.iam.node_group_role_arn
  node_cni_policy = module.iam.node_cni_policy
  node_worker_policy = module.iam.node_worker_policy
  node_ecr_policy = module.iam.node_ecr_policy
  disk_size_app = 20
  disk_size_obs = 30
  
  app_ondemand_nodes = {
  instance_type = "t3.xlarge"
  min           = 1 #2
  max           = 2 #2
  desired       = 1 #2
  }
  # App node group — Spot scaling
  app_spot_nodes = {
    instance_types = ["t3.xlarge", "m5.xlarge", "m3.xlarge", "t3.medium", "m5.large"]  
    min           = 0
    max           = 1 #8
    desired       = 0
  }
  
  # Observability node group
  obs_nodes = {
    instance_type = "m5.large"
    min           = 1 #2 
    max           = 2 #4
    desired       = 1 #2
    taint_key     = "dedicated"
    taint_value   = "observability"
    taint_effect  = "NO_SCHEDULE"
  }
  tags = {
    Project = var.project_name
    environment = "prod"
  }

}

module "iam" {
  source = "../../modules/iam"
  project_name = var.project_name
  oidc_provider_arn = module.eks.oidc_provider_url
  tags = {
    Project = var.project_name
  }
}


module "rds" {
  source = "../../modules/rds"
  project_name = var.project_name
  private_subnet_ids = module.vpc.private_subnets
  vpc_id = module.vpc.vpc_id
  
}

resource "aws_ecr_repository" "backend" {
  name = "production/backend"
  force_delete = true
}


