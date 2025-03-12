# Common Variables
variable "project" {
  description = "Project name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "owner" {
  description = "Owner"
  type        = string
}

# Network Variables
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_id" {
  description = "Public Subnet ID"
  type        = string
}

# Instance Variables
variable "ssh_public_key" {
  description = "SSH public key"
  type        = string
}

variable "ami_id" {
  description = "AMI ID"
  type        = string
}

variable "platform" {
  description = "Platform"
  type        = string
}

variable "instance_type" {
  description = "Instance type"
  type        = string
}

# Secrets
variable "dcv_username" {
  description = "DCV username"
  type        = string
}

variable "dcv_password" {
  description = "DCV password"
  type        = string
}

variable "ingress_ipv4" {
  description = "Ingress IPv4 CIDR"
  type        = string
  default = "0.0.0.0/0"
}

variable "ingress_ipv6" {
  description = "Ingress IPv6 CIDR"
  type        = string
  default = "::/0"
}

variable "listen_port" {
  description = "Port to listen on"
  type        = number
  default     = 8443
}

variable "instance_connect_ip" {
  description = "Instance connect IP"
  type        = string
  default = "18.206.107.24/29"
}

variable "volume_size" {
  description = "Volume size"
  type        = number
  default     = 100
}