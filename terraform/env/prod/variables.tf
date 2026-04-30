variable "ACCOUNT_ID" {
  type = string
  description = "AWS Account ID"
}

variable "region" {
  type = string
  description = "AWS Region"
}
variable "project_name" {
  type = string
  description = "project Name"
}
variable "domain" {
    description = "domain name product"
    type = string
    default = "glodios.in"
  
}