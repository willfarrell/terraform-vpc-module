
variable "name" {
  type    = string
  default = ""
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  type = string
  description = "VPC ID"
}

variable "endpoints" {
  type = list(string)
  description = "list of endpoint ids"
  default = [
    # Required for Security Hub
    # "ec2",
    # "ssm", "ssm-contacts", "ssm-incidents", #
    # "ecr.api", "ecr.dkr",                   # ECS
  ]
}

variable "private_dns_enabled" {
  type = bool
  description = "must only be applied once"
  default = false
}

variable "allowed_subnet_ids" {
  description = "List of VPC subnet ids to associate access to VPC endpoints"
  type        = list(string)
  default     = []
}

variable "allowed_route_tables" {
  description = "List of VPC route tbles to associate access to VPC endpoints"
  type        = list(string)
  default     = []
}

variable "allowed_security_groups" {
  description = "List of VPC security groups to associate access to VPC endpoints"
  type        = list(string)
  default     = []
}