variable "prefix" {
  type = string
  description = "Prefix for the ECS service"
  default = "intraverse-utils"
}

variable "ecs_cluster_id" {
  type = string
  description = "ID of the ECS cluster"
  default = "intraverse-dev-dcv"
#   default = "arn:aws:ecs:us-east-1:585415957264:cluster/intraverse-dev-dcv"
}

variable "task_definition_arn" {
  type = string
  description = "ARN of the task definition"
  default = "arn:aws:ecs:us-east-1:585415957264:task-definition/dcv:23"
}

variable "private_subnets" {
  type = list(string)
  description = "List of private subnets"
  default = ["subnet-0c69d52012287b553", "subnet-02180354e2c187020", "subnet-0fa0d2c444c2e2b30"]
}

variable "capacity_provider_name" {
  type = string
  description = "Name of the capacity provider"
  default = "intraverse-dev-dcv-server"
}

variable "tags" {
  type = map(string)
  description = "Tags to apply to the ECS service"
  default = {
    Project = "Intraverse"
    Environment = "Development"
    ManagedBy = "Terraform"
    Owner = "jay@terrazero.com"
  }
}

resource "aws_ecs_service" "dcv" {
  name            = "${var.prefix}-dcv"
  cluster         = var.ecs_cluster_id
  
  task_definition = var.task_definition_arn
  desired_count   = 0
  health_check_grace_period_seconds = 500

  network_configuration {
    subnets          = var.private_subnets
    security_groups = [aws_security_group.dcv-nlb.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.dcv-nlb-tcp-udp.arn
    container_name   = "dcv"
    container_port   = 8443
  }

  capacity_provider_strategy {
    base = 0
    capacity_provider = var.capacity_provider_name
    weight = 100
  }

  tags = merge(var.tags, {
    Name = "${var.prefix}-dcv"
  })
}