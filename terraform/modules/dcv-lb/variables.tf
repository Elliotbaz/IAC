# variables.tf

variable "project" {
  type = string
  default = "Project"
}

variable "environment" {
  type = string
  default = "Environment"
}

variable "region" {
  type = string
  default = "us-east-1"  
}

variable "tags" {
  type = map(string)
  default = {
    ManagedBy = "Terraform"
  }  
}

variable "prefix" {
  type = string
  default = "project-env"  
}

variable "suffix" {
  type = string
  default = "abcd1234"  
}

# network

variable "vpc_id" {
  type = string
}

variable "public_subnets" {
  type = list(string)
  default = []
}

variable "certificate_arn" {
  type = string
}