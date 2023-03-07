variable "name" {
  type    = string
  default = ""
}

variable "default_tags" {
  type    = map(string)
  default = {}
}

//variable "cost_id" {
//  default = "none"
//}

variable "az_count" {
  type    = number
  default = 9
}

variable "cidr_block" {
  default = "10.0.0.0/16"
}

# NAT vars
variable "nat_type" {
  default = "none"
}

variable "iam_user_groups" {
  default = ""
}

variable "iam_sudo_groups" {
  default = ""
}

variable "instance_type" {
  default = "t3a.nano" # t4g.nano
}

variable "use_spot_instance" {
  type        = bool
  description = "Use spot for NAT instances"
  default     = false
}

variable "volume_type" {
  default = "gp2"
}

variable "volume_size" {
  type    = number
  default = 8
}

variable "key_name" {
  default = ""
}

variable "ami_account_id" {
  type    = string
  default = "self"
}

variable "endpoints" {
  type    = list(string)
  default = []
}
