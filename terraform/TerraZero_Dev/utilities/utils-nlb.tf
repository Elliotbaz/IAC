
# Network Load Balancer
resource "aws_lb" "dcv-server" {
  name                             = "${local.prefix}-dcv-nlb-${local.suffix}"
  load_balancer_type               = "network"
  ip_address_type                  = "ipv4"
  internal                         = false
  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = true
  desync_mitigation_mode           = "strictest"
  security_groups = [aws_security_group.dcv-nlb.id]

  subnets = local.public_subnets
}

resource "aws_lb_target_group" "dcv-nlb-tcp-udp" {
  name     = "${local.prefix}-dcv-nlb-tcp-udp"
  port     = 8443
  protocol = "TCP_UDP"
  vpc_id   = local.vpc_id
  preserve_client_ip = true
  connection_termination = true
  target_type = "ip"

  stickiness {
    type = "source_ip"
    enabled = true
  }

    health_check {
        port = 8443
        protocol = "TCP"
        healthy_threshold = 10
        unhealthy_threshold = 10
    }
}

resource "aws_lb_listener" "dcv-nlb-tcp-udp" {
  load_balancer_arn = aws_lb.dcv-server.arn
  port              = 8443
  protocol          = "TCP_UDP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dcv-nlb-tcp-udp.arn
  }
}

resource "aws_lb_target_group" "dcv-nlb-udp" {
  name     = "${local.prefix}-dcv-nlb-udp-tg"
  port     = 8443
  protocol = "UDP"
  vpc_id   = local.vpc_id
  target_type = "ip"
}

# Create a second target group that is identical to the first one, but with a different name
resource "aws_lb_target_group" "dcv-nlb-tcp-udp-2" {
  name     = "${local.prefix}-dcv-nlb-tcp-udp-2"
  port     = 8443
  protocol = "TCP_UDP"
  vpc_id   = local.vpc_id
  target_type = "ip"
}

# Create a second listener that forwards to the second target group
resource "aws_lb_listener" "dcv-nlb-tcp-udp-2" {
  load_balancer_arn = aws_lb.dcv-server.arn
  port              = 8443
  protocol          = "TCP_UDP"

  default_action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.dcv-nlb-tcp-udp-2.arn
      }
    }
  }

  # condition {
  #   path_pattern {
  #     values = ["/user2"]
  #   }
  # }
}


######################################
## Security Groups
######################################

# nlb security group 
resource "aws_security_group" "dcv-nlb" {
  name = "${local.prefix}-dcv-nlb-sg"
  vpc_id = local.vpc_id
  tags = local.common_tags
}

resource "aws_security_group_rule" "dcv-nlb-ingress" {
  type = "ingress"
  from_port = 8443
  to_port = 8443
  protocol = "tcp"
  security_group_id = aws_security_group.dcv-nlb.id
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "dcv-nlb-egress" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  security_group_id = aws_security_group.dcv-nlb.id
  cidr_blocks = ["0.0.0.0/0"]
}

# alb security group rule
resource "aws_security_group_rule" "dcv-nlb-alb-ingress" {
  type = "ingress"
  from_port = 8443
  to_port = 8443
  protocol = "tcp"
  security_group_id = local.dcv_server_alb_sg
  source_security_group_id = aws_security_group.dcv-nlb.id
}