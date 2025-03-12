variable "ami_hash" {
  type    = string
  default = "cd3deba"
}

variable "game_version" {
  type    = string
  default = "1_3_9"
}

variable "ami_id" {
  type    = string
  default = "ami-0d00d12af98ec6a9f"
}

variable "instance_type" {
  type    = string
  default = "g4dn.xlarge"
}

variable "key_name" {
  type    = string
  default = "intraverse-development-dcv-server"
}

variable "iam_instance_profile" {
  type    = string
  default = "intraverse-dev-dcv-builder-18f71b13"
}

variable "subnet_id" {
  type    = string
  default = "subnet-0c5e5f6b346f46246"
}

variable "security_group_id" {
  type    = string
  default = "sg-037d7123ccd862c41"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "log_group_name" {
  type    = string
  default = "intraverse-dev-dcv-server-host"
}
