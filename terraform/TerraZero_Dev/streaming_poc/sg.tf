resource "aws_security_group" "poc_instance" {
  name   = lower("${var.project}-${var.environment}-poc-instance-sg")
  vpc_id = var.vpc_id

  # These will be hardened to some degree for the MVP, and then further for production
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # loop through common tags and add them to the security group, as well as the Name tag  
  tags = merge(local.common_tags, {
    Name = lower("${var.project}-${var.environment}-poc-instance-sg")
  })
}
