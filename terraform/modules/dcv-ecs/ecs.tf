resource "aws_ecs_cluster" "dcv" {
  name = "${var.prefix}-dcv"
  tags = merge(var.tags, {
    Name = "${var.prefix}-dcv"
  })
}

resource "aws_ecs_task_definition" "dcv" {
  family                   = "dcv"
  network_mode             = "awsvpc"
  requires_compatibilities = [ "EC2" ]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "dcv"
      image = "${var.dcv_ecr_url}:dcv" # This has been moved outside the module. Need to pass as a variable to the module.
      portMappings = [
        {
          containerPort = 8443
          host_port = 8443
          protocol = "tcp"
        }
      ]
      resourceRequirements = [
        {
          type = "GPU"
          value = "1"
        }
      ]
    }
  ])

  # volume {
  #   name      = "unity-builds"
  #   host_path = "/mnt/shared/unity-builds"
  # }
}

# DCV Service with Capacity Provider Strategy
resource "aws_ecs_service" "dcv" {
  depends_on = [ aws_lb_target_group.dcv-server ]

  name            = "${var.prefix}-dcv"
  cluster         = aws_ecs_cluster.dcv.id
  
  task_definition = aws_ecs_task_definition.dcv.arn
  # desired_count   = var.deploy_compute ? 2 : 0 # disabling for now to test
  desired_count   = 1
  health_check_grace_period_seconds = 500

  network_configuration {
    subnets          = var.private_subnets
    security_groups = [var.alb_sg_id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.dcv-server.arn
    container_name   = "dcv"
    container_port   = 8443
  }

  capacity_provider_strategy {
    base = 0
    capacity_provider = aws_ecs_capacity_provider.dcv-server.name
    weight = 100
  }

  tags = merge(var.tags, {
    Name = "${var.prefix}-dcv"
  })
}

resource "aws_ecs_task_definition" "nginx-ec2" {
  family                   = "nginx"
  network_mode             = "awsvpc"
  requires_compatibilities = [ "EC2" ]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "nginx"
      image = "${var.dcv_ecr_url}:nginx"
      portMappings = [
        {
          containerPort = 80
          host_port = 80
          protocol = "tcp"
        }
      ]
    }
  ])
}

# ecs.tf

# Nginx Service with Capacity Provider Strategy
resource "aws_ecs_service" "nginx-ec2" {
  depends_on = [ aws_lb_target_group.nginx-ec2 ]

  name            = "${var.prefix}-nginx-ec2"
  cluster         = aws_ecs_cluster.dcv.id
  
  task_definition = aws_ecs_task_definition.nginx-ec2.arn
  # desired_count   = var.deploy_compute ? 2 : 0
  desired_count = 0
  health_check_grace_period_seconds = 300

  network_configuration {
    subnets          = var.private_subnets
    security_groups = [var.alb_sg_id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.nginx-ec2.arn
    container_name   = "nginx"
    container_port   = 80
  }

  capacity_provider_strategy {
    base = 0
    capacity_provider = aws_ecs_capacity_provider.dcv-server.name
    weight = 100
  }

  tags = merge(var.tags, {
    Name = "${var.prefix}-nginx-ec2"
  })
}