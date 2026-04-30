variable "project_name" {
    type = string
    description = "project Name"
  
}

variable "private_subnet_ids" {
    type = list(string)
    description = "List of private subnet IDs for RDS deployment"
}
variable "vpc_id" {
    type = string
    description = "VPC ID for RDS deployment"
}