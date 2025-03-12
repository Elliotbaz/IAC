locals {
    common_tags = {
        Project     = var.project
        Environment = var.environment
        ManagedBy   = "Terraform"
    }
}

# ##################
# # Resources
# ##################

# Set up a trust relationship between the github actions role in the management account and the Terraform role in the member account
resource "aws_iam_role" "github_actions_member" {
  name = "${var.project}-${var.environment}-github-actions-member"
  description = "Role for GitHub Actions to assume in the member account to manage infrastructure resources."
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Principal": {
            "AWS": "${var.github_idp_role_arn}"
        },
        "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "github_actions_member" {
  name        = "${var.project}-${var.environment}-github-actions-member"
  role = aws_iam_role.github_actions_member.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "ec2:DescribeInstances",
          "ec2:CreateSecurityGroup",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteSecurityGroup",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeTags",
          "ec2:DescribeInstanceAttribute",
          "ec2:DescribeVolumes",
          "ec2:DescribeInstanceCreditSpecifications",
          "ec2:TerminateInstances",
          "ec2:DescribeRegions"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "ec2:CreateVpc",
          "ec2:DescribeVpcs",
          "ec2:CreateSubnet",
          "ec2:DescribeSubnets",
          "ec2:DeleteVpc",
          "ec2:DeleteSubnet",
          "ec2:DescribeRouteTables",
          "ec2:CreateRoute",
          "ec2:CreateRouteTable",
          "ec2:AssociateRouteTable",
          "ec2:CreateNatGateway",
          "ec2:DescribeNatGateways",
          "ec2:DeleteNatGateway",
          "ec2:CreateTags",
          "ec2:ModifyVpcAttribute",
          "ec2:DescribeVpcAttribute",
          "ec2:DescribeInternetGateways",
          "ec2:AttachInternetGateway",
          "ec2:CreateInternetGateway",
          "ec2:DeleteInternetGateway",
          "ec2:DetachInternetGateway",
          "ec2:DescribeNetworkAcls",
          "ec2:DisassociateRouteTable",
          "ec2:DeleteRouteTable",
          "ec2:DeleteRoute",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeAvailabilityZones",
          "ec2:AllocateAddress",
          "ec2:AssociateAddress",
          "ec2:DescribeAddresses",
          "ec2:DescribeSecurityGroupRules",
          "ec2:DeleteNetworkAclEntry",
          "ec2:DeleteNetworkAcl",
          "ec2:CreateNetworkAcl",
          "ec2:CreateNetworkAclEntry",
          "ec2:DescribeAddressesAttribute",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:ReleaseAddress",
          "ec2:CreateLaunchTemplate",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:DeleteLaunchTemplate",
          "ec2:RunInstances",
          "ec2:CreateLaunchTemplateVersion",
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "s3:CreateBucket",
          "s3:GetBucketPolicy",
          "s3:GetBucketAcl",
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:GetBucketCors",
          "s3:GetBucketWebsite",
          "s3:GetBucketVersioning",
          "s3:GetBucketAccelerateConfiguration",
          "s3:DeleteBucket",
          "s3:GetBucketLocation",
          "s3:PutBucketPolicy",
          "s3:DeleteBucketPolicy",
          "s3:PutBucketTagging",
          "s3:DeleteBucketTagging",
          "s3:PutBucketVersioning",
          "s3:ListObjectsV2"
        ]
        Resource = "arn:aws:s3:::*"
      },
      {
        Effect: "Allow",
        Action: ["s3:*"],
        Resource: ["*"]
      },
      {
        Effect: "Allow",
        Action: ["s3:*"],
        Resource: ["arn:aws:s3:::fastlane-signing-certificates-*"]
      },
      {
        Effect   = "Allow"
        Action   = [
          "elasticloadbalancing:DescribeLoadBalancers",
          "ec2:AuthorizeSecurityGroupEgress",
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeTags",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeListenerAttributes",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DeleteRule"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "ecs:CreateCluster",
          "ecr:CreateRepository",
          "ecr:DescribeRepositories",
          "ecs:TagResource",
          "ecr:ListTagsForResource",
          "ecr:DeleteRepository",
          "ecs:DescribeClusters",
          "ecs:DeleteCluster",
          "ecs:ListClusters",
          "ecs:UpdateClusterSettings",
          "ecs:RegisterTaskDefinition",
          "ecs:DescribeTaskDefinition",
          "ecs:DeregisterTaskDefinition",
          "ecs:CreateCapacityProvider",
          "ecs:DescribeCapacityProviders",
          "ecs:DeleteCapacityProvider",
          "ecs:UpdateCapacityProvider",
          "ecs:PutClusterCapacityProviders",
          "ecs:CreateService",
          "ecs:DescribeServices",
          "ecs:UpdateService",
          "ecs:DeleteService",
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "iam:CreateRole",
          "iam:AttachRolePolicy",
          "iam:GetRole",
          "iam:ListRoles",
          "iam:CreatePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListPolicyVersions",
          "iam:DeletePolicy",
          "iam:DeleteRole",
          "iam:PutRolePolicy",
          "iam:CreateInstanceProfile",
          "iam:PassRole",
          "iam:GetRolePolicy",
          "iam:GetInstanceProfile",
          "iam:DeleteRolePolicy",
          "iam:DeleteInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:DetachRolePolicy",
          "iam:CreatePolicyVersion"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "autoscaling:CreateAutoScalingGroup",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:DeleteAutoScalingGroup",
          "autoscaling:CreateOrUpdateTags",
          "autoscaling:DescribeTags",
          "autoscaling:DeleteTags",
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:PutRetentionPolicy",
          "logs:DescribeLogGroups",
          "logs:ListTagsForResource",
          "logs:DeleteLogGroup",
          "logs:ListTagsLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "logs:GetLogEvents",
          "logs:GetLogGroupFields",
          "logs:GetLogRecord",
          "logs:GetQueryResults",
          "logs:StartQuery",
          "logs:StopQuery",
          "logs:DeleteLogStream",
          "logs:DeleteLogGroup",
          
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "iam:CreateServiceLinkedRole"
        ]
        Resource = "arn:aws:iam::*:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "ec2:CreateImage",
          "ec2:CopyImage",
          "ec2:DeregisterImage",
          "ec2:DescribeImages",
          "ec2:RegisterImage",
          "ec2:ModifyImageAttribute",
          "ec2:CreateSnapshot",
          "ec2:DeleteSnapshot",
          "ec2:DescribeSnapshots",
          "ec2:ModifySnapshotAttribute",
          "ec2:CreateKeyPair",
          "ec2:DeleteKeyPair",
          "ec2:DescribeKeyPairs",
          "ec2:ImportKeyPair",
          "ec2:StopInstances",
          "ec2:StartInstances",
          "ec2:GetPasswordData"
        ]
        Resource = "*"
      }
    ]
  })
}
