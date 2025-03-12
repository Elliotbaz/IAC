# ecr
resource "aws_ecr_repository" "dcv" {
  name = "${local.prefix}-dcv"
}

resource "aws_ecs_cluster" "dcv" {
  name = "${local.prefix}-dcv"
  tags = merge(local.common_tags, {
    Name = "${local.prefix}-dcv"
  })
}

resource "aws_cloudwatch_log_group" "dcv-cm-api-log-group" {
  name = "/ecs/dcv-cm-api"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_stream" "dcv-cm-api-log-stream" {
  name = "dcv-cm-api"
  log_group_name = aws_cloudwatch_log_group.dcv-cm-api-log-group.name
}

resource "aws_iam_service_linked_role" "ecs_service_role" {
  aws_service_name = "ecs.amazonaws.com"
}

resource "aws_ecs_service" "dcv-cm-api-service" {
  name = "dcv-cm-api-service"
  cluster = aws_ecs_cluster.dcv.id
  task_definition = aws_ecs_task_definition.dcv-cm-api-task-definition.arn
  desired_count = 1
  launch_type = "FARGATE"
  network_configuration {
    subnets = module.vpc.private_subnets
    security_groups = [module.alb.security_group_id]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.dcv-cm-api-target-group.arn
    container_name = "dcv-cm-api-container"
    container_port = 5000
  }
}

################################################################################

resource "aws_lb_target_group" "dcv-cm-api-target-group" {
  name = "dcv-cm-api-target-group"
  port = 5000
  protocol = "HTTP"
  vpc_id = module.vpc.vpc_id
  target_type = "ip"
  health_check {
    path = "/health"
    port = "5000"
    protocol = "HTTP"
    healthy_threshold = 5
    unhealthy_threshold = 5
    timeout = 15
    interval = 30
  }
}

resource "aws_lb_listener_rule" "dcv-cm-api-listener-rule" {
  listener_arn = module.alb.https_listener_id
  priority = 20

  condition {
    path_pattern {
      values = [
        "/api/v2/*", 
        "/api/v2/*/*",
        "/docs",
        "/docs*",
        "/swagger.yaml"
      ]
    }
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.dcv-cm-api-target-group.arn
  }
}

resource "aws_ecs_task_definition" "dcv-cm-api-task-definition" {
  family = "dcv-cm-api-task-definition"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu = "512"
  memory = "1024"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn = aws_iam_role.dcv_cm_api_ecs_task_role.arn
  container_definitions = jsonencode([
    {
      name = "dcv-cm-api-container"
      image = "${aws_ecr_repository.dcv.repository_url}:2.0.0"
      essential = true
      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group = aws_cloudwatch_log_group.dcv-cm-api-log-group.name
          awslogs-region = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
      environment = [
        {
          name  = "MONGODB_URI"
          value = "mongodb://root:rootpassword@localhost:27017/connection_manager?authSource=admin&directConnection=true"
        },
        {
          name  = "PORT"
          value = "5000"
        }
      ]
      dependsOn = [
        {
          containerName = "mongo"
          condition = "HEALTHY"
        }
      ]
    },
    {
      name = "mongo"
      # image = "${aws_ecr_repository.dcv-cm-apiv2.repository_url}:mongo"
      image = "mongo:latest"
      essential = true
      portMappings = [
        {
          containerPort = 27017
          hostPort      = 27017
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "MONGO_INITDB_ROOT_USERNAME"
          value = "root"
        },
        {
          name  = "MONGO_INITDB_ROOT_PASSWORD"
          value = "rootpassword"
        },
        {
          name  = "MONGO_INITDB_DATABASE"
          value = "connection_manager"
        },
        {
          name  = "STAGE"
          value = "dev"
        },
        {
          name  = "PORT"
          value = "8080"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group = aws_cloudwatch_log_group.dcv-cm-api-log-group.name
          awslogs-region = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
      # Add volume mount for data persistence
      mountPoints = [
        {
          sourceVolume  = "mongodb_data"
          containerPath = "/data/db"
          readOnly      = false
        }
      ]
      healthCheck = {
        command     = [
          "CMD-SHELL",
          "echo 'db.runCommand({ping:1})' | mongosh admin -u root -p rootpassword --quiet || exit 1"
        ]
        interval    = 30
        timeout     = 10
        retries     = 3
        startPeriod = 40
      }
    }
  ])

  # Add volume definition
  volume {
    name = "mongodb_data"

  }
}

################################################################################
# IAM
################################################################################

resource "aws_iam_role" "dcv_cm_api_ecs_task_role" {
  name = "${local.prefix}-dcv-cm-api-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "dcv_cm_api_ecs_task_role_policy_attachment" {
  role       = aws_iam_role.dcv_cm_api_ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "dcv_cm_api_ecs_task_role_policy" {
  name = "${local.prefix}-dcv-cm-api-ecs-task-role-policy"
  role = aws_iam_role.dcv_cm_api_ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:AttachNetworkInterface",
          "ec2:DetachNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses",
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "ec2:CreateTags",
          "ssm:SendCommand"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:ExecuteCommand"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = "arn:aws:iam::${local.account_id}:role/${local.prefix}-ecs-instance-role"
      }
    ]
  })
}


resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${local.prefix}-dcv-cm-api-ecs-task-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_task_execution_role_policy" {
  name = "${local.prefix}-ecs-task-execution-role-policy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecs:UpdateService",
          "ecs:RunTask",
          "ecs:ListTaskDefinitions",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "ecs:ExecuteCommand"
        ]
        Resource = "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "ec2:AttachNetworkInterface",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DetachNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeTags"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "ecs:CreateCluster",
          "ecs:DeregisterContainerInstance",
          "ecs:DiscoverPollEndpoint",
          "ecs:Poll",
          "ecs:RegisterContainerInstance",
          "ecs:StartTelemetrySession",
          "ecs:Submit*",
          "ecs:ExecuteCommand",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "iam:PassRole"
        ],
        "Resource": aws_iam_role.ecs_task_execution_role.arn
      },
      {
        "Effect": "Allow",
        "Action": [
          "ec2:DescribeInstances",
          "ec2:DescribeTags"
        ],
        "Resource": "*"
      }
    ]
  })
}


################################################################################
# Security Groups
################################################################################


resource "aws_security_group_rule" "allow_8080_from_alb" {
  type = "ingress"
  from_port = 8080
  to_port = 8080
  protocol = "tcp"
  security_group_id = module.alb.security_group_id
  source_security_group_id = module.alb.security_group_id
}

resource "aws_security_group_rule" "allow_mongodb_internal" {
  type                     = "ingress"
  from_port               = 27017
  to_port                 = 27017
  protocol                = "tcp"
  security_group_id       = module.alb.security_group_id
  source_security_group_id = module.alb.security_group_id
}

resource "aws_security_group_rule" "allow_5000_from_alb" {
  type = "ingress"
  from_port = 5000
  to_port = 5000
  protocol = "tcp"
  security_group_id = module.alb.security_group_id
  source_security_group_id = module.alb.security_group_id
}

resource "aws_security_group_rule" "allow_53_from_alb" {
  type = "ingress"
  from_port = 53
  to_port = 53
  protocol = "tcp"
  security_group_id = module.alb.security_group_id
  source_security_group_id = module.alb.security_group_id
}
