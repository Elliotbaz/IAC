variable "prefix" {
  type = string
  default = "project-env"
}

variable "environment" {
  type = string
}

variable "tags" {
  type = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}

variable "deploy_builder" {
  type = bool
}

variable "instance_type" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "ssh_key_name" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "object_bucket" {
  type = string
}