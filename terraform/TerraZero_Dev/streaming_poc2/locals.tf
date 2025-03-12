resource "random_id" "suffix" {
  byte_length = 8
}

locals {
  # Common Variables
  project     = "Intraverse"
  region      = "us-east-1"
  environment = "Dev"
  suffix      = random_id.suffix.hex

  # Default Network Variables
  default_vpc_id           = "vpc-03e7102dc062eb065"
  default_public_subnet_id = "subnet-023f28706d6b85a31"

  # Instance Variables
  ubuntu_ami = "ami-080e1f13689e07408"
}