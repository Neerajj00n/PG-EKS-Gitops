variable "project_name" {
  type = string
  description = "project Name"
}
variable "private_subnet_ids" {
  type = list(string)
}
variable "public_access_cidrs" {
  type = list(string)
}

variable "coredns_version" {
  type = string
  default = ""
}
variable "eks_role_arn" {
  type = string
}
variable "node_group_role_arn" {
  type = string
}
variable "tags" {
  type = map(string)
  description = "tags for resources"
}
variable "vpc_cni_version" {
  type = string
  default = ""
}
variable "kube_proxy_version" {
  type = string
  default = ""
}
variable "vpc_id" {
  type = string
}
variable "cluster_version" {
    type = string

}

variable "disk_size_app" {
  type = number
}

variable "disk_size_obs" {
  type = number
}
variable "app_ondemand_nodes" {
  type = object({
    instance_type = string
    min           = number
    max           = number
    desired       = number
  })
}

variable "app_spot_nodes" {
  type = object({
    instance_types = list(string)
    min            = number
    max            = number
    desired        = number
  })
}

variable "obs_nodes" {
  type = object({
    instance_type = string
    min           = number
    max           = number
    desired       = number
    taint_key     = string
    taint_value   = string
    taint_effect  = string
  })
}

variable "node_cni_policy" {
  type = object({
  })
}

variable "node_worker_policy" {
  type = object({
  })
  
}
variable "node_ecr_policy" {
  type = object({
   })
}



variable "cluster_creator_arn" {
  description = "ARN of the user who created the cluster (admin access)"
  type        = string
  # Example: arn:aws:iam::887709589787:user/terraform-deployment-user
}

variable "additional_users" {
  description = "Additional IAM users to grant access"
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
  # Example:
  # [
  #   {
  #     userarn  = "arn:aws:iam::887709589787:user/devops-team"
  #     username = "devops-user"
  #     groups   = ["system:masters"]
  #   }
  # ]
}
