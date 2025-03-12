module "streaming_poc" {
  source = "./streaming_poc"

  # Common Variables
  project     = local.project
  region      = local.region
  environment = local.environment
  owner       = "jay@terrazero.com"

  # Network Variables
  vpc_id           = local.default_vpc_id
  public_subnet_id = local.default_public_subnet_id

  # Instance Variables
  ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDEQJ15/mTnLYfIY5ojL9F10u2bmc7ofI+v5RneRg86q6FTu2ls/hKF1otWdbhaS9hkB0aK/vNGbq1jAvgLx6e2VG5+3gLkTNr0jZU8xNdv1IcpAPeQVQxFzW2xs2+Bgtm/dH8ugU1yDDlvo8JgDK8u1kRJOjtRCrD5Ixe+TYX+OCoNIPYSlLA5S3vXldY4SKWbn8RTjWGFskcHF/aIRk6TgpVFEwpuvcvxGstUWWMQEOdfF0EUpuZrALdTN2kHXsIdJwCV69nxLKG1Bf6GDcOGmD3LsHthT7UL7SKWU+NFkHleUyzY2ET5QyCfdSYQSrRD5q//5Qc3rXMuxczB+xf5KqGzLG/M1PEnAPYB/K5feN0NNPl/40wzSb9a8AbuC20RH2Sd3vWuoX44vsiTXv3MSMrL5zAzOMV0Xh7ziZMmN8ic7Qm/CoBSKlrKAWlLv6oxO77UfrEqCWI5vFGWwfwQbDTG8TckVk896mumvzrIdzAXQkHwAeQnui5mBg0+vjy7cpA6eHE4EhgD1pLzHPf54Y8FVmfm4b1fH4fXf8Daba2LnXlB2SfBprlTJ34fI504vnMjehIWpnJtdKq6fJtduVGs+Fchu72pti/Vysy4DF1NIKZGrPWfEoPdYXNdoB0MHfLbfef4Sif3dorNkSbCh4cIrCsIWsnp478RXo5m2Q=="
  ami_id         = local.ubuntu_ami
}