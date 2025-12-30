variable "name" {
  type    = string
  default = ""
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}

variable "az_count" {
  description = "max number of AZ, will only use the max allowed be region"
  type    = number
  default = 9
}

variable "cidr_block" {
  description = "IPv4 CIDR to use for subnets /16"
  type = string
  default = "10.0.0.0/16"
}

## LB vars
variable "lb_type" {
  description = "TODO `alb`, `nlb`, `glb`"
  type = string
  default = "none"
}

# NAT vars
variable "nat_type" {
  description = "`regional`, `zonal` (adds subnet), `none` (default)"
  type = string
  default = "none"
}

# RDS
variable "rds_port" {
  description = "RDS port number to allow `private-egress` ACL access to `private` ACL"
  type = number
  default = null
}