variable "project_name" {
    type = string
    description = "project Name"
  
}

variable "tags" {
    type = map(string)
    description = "tags for resources"
  
}


variable "oidc_provider_url" {
  type = string
  description = "URL of the OIDC provider"
}
variable "oidc_provider_arn" {
  type = string
  description = "ARN of the OIDC provider"
}