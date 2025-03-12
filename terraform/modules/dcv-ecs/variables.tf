variable "prefix" {
  type = string
  default = "project-env"
}

variable "tags" {
  type = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}

variable "environment" {
  type = string
}

variable "dcv_ecr_url" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "dcv_server_listener_id" {
  type = string
}

variable "https_listener_id" {
  type = string
}

variable "domain" {
  type = string
}

variable "ssh_key_name" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "alb_sg_id" {
  type = string
}

variable "deploy_compute" {
  type = bool
}

variable "private_subnets" {
  type = list(string)
}

variable "object_bucket" {
  type = string
}