################################################################################
# CloudWatch Log Group
################################################################################

resource "aws_cloudwatch_log_group" "dcv-builder" {
  name = "${local.prefix}-dcv-server-${local.suffix}"
  retention_in_days = 7
}

################################################################################
# S3 Bucket
################################################################################

resource "aws_s3_bucket" "dcv-builder" {
  bucket = "${local.prefix}-dcv-builder-${local.suffix}"
  tags = local.common_tags
}

################################################################################
# Autoscaling Group
################################################################################

resource "aws_launch_template" "dcv_server" {
  name_prefix   = "dcv-server-"
  image_id      = local.dcv_ami_id
  instance_type = "g4dn.xlarge"
  key_name      = "intraverse-dcv-server-prod"

  iam_instance_profile {
    name = aws_iam_instance_profile.dcv-builder.name
  }

  network_interfaces {
    associate_public_ip_address = true
    device_index                = 0
    subnet_id                   = module.vpc.public_subnets[0]
    security_groups             = [aws_security_group.dcv-builder.id]
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
  }
}

resource "aws_autoscaling_group" "dcv_server_asg" {
  name_prefix         = "dcv-server-asg-"
  min_size            = 0
  max_size            = 4  # Adjust based on your scaling needs
  desired_capacity    = 1
  vpc_zone_identifier = [module.vpc.public_subnets[0]]  # Use the same subnet as in the launch template

  launch_template {
    id      = aws_launch_template.dcv_server.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "dcv-server-host-${local.dcv_ami_version}-intraverse-${local.intraverse_version}"
    propagate_at_launch = true
  }

  tag {
    key                 = "ami-id"
    value               = local.dcv_ami_id
    propagate_at_launch = true
  }

  tag {
    key                 = "version"
    value               = local.dcv_ami_version
    propagate_at_launch = true
  }

  tag {
    key                 = "intraverse-version"
    value               = local.intraverse_version
    propagate_at_launch = true
  }

  tag {
    key                 = "Stage"
    value               = "prod"
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "dcv-cm-api"
    propagate_at_launch = true
  }

  tag {
    key                 = "ports"
    value               = "[{\"8080\":\"available\"},{\"8081\":\"available\"}]"
    propagate_at_launch = true
  }

  tag {
    key                 = "port-8080"
    value               = "available"
    propagate_at_launch = true
  }

  tag {
    key                 = "port-8081"
    value               = "available"
    propagate_at_launch = true
  }
}

################################################################################
# Security Group
################################################################################

resource "aws_security_group" "dcv-builder" {
  name = "${local.prefix}-dcv-builder"
  description = "Security group for the dcv builder"
  vpc_id = module.vpc.vpc_id
}

# This needs to only allow specific ports
resource "aws_security_group_rule" "allow_all_ingress" {
  type        = "ingress"
  from_port   = 0
  to_port     = 65535
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.dcv-builder.id
}

resource "aws_security_group_rule" "allow_all_egress" {
  type        = "egress"
  from_port   = 0
  to_port     = 65535
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.dcv-builder.id
}

####################
# IAM
####################

resource "aws_iam_instance_profile" "dcv-builder" {
  name = "${local.prefix}-dcv-builder-${local.suffix}"
  path = "/"
  role = aws_iam_role.dcv-builder.name
}

resource "aws_iam_role" "dcv-builder" {
  name = "${local.prefix}-dcv-builder-${local.suffix}"
  path = "/"
  assume_role_policy = data.aws_iam_policy_document.dcv-builder.json
}

data "aws_iam_policy_document" "dcv-builder" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role = aws_iam_role.dcv-builder.name
  policy_arn = aws_iam_policy.cloudwatch.arn
}
resource "aws_iam_policy" "cloudwatch" {
  name = "${local.prefix}-dcv-builder-${local.suffix}-cloudwatch"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = aws_cloudwatch_log_group.dcv-builder.arn 
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3" {
  role = aws_iam_role.dcv-builder.name
  policy_arn = aws_iam_policy.s3.arn
}

resource "aws_iam_policy" "s3" {
  name = "${local.prefix}-dcv-builder-${local.suffix}-s3"
  description = "Allows the DCV Builder instance to pull scripts from the S3 bucket"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketVersions",
          "s3:GetObjectVersion"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role = aws_iam_role.dcv-builder.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryFullAccess" {
  role = aws_iam_role.dcv-builder.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerServiceforEC2Role" {
  role = aws_iam_role.dcv-builder.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

output "dcv-host" {
  value = {
    instance_profile = aws_iam_instance_profile.dcv-builder.name
    security_group = aws_security_group.dcv-builder.id
  }
}