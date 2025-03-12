resource "aws_security_group" "dcv-builder-asg" {
  name        = "${var.prefix}-dcv-builder-asg"
  description = "Allow ingress from ALB"
  vpc_id      = var.vpc_id
}

# TODO: Deploy a vpn and harden these rules
resource "aws_security_group_rule" "allow-all-ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "TCP"
  security_group_id = aws_security_group.dcv-builder-asg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow-all-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.dcv-builder-asg.id
  cidr_blocks       = ["0.0.0.0/0"]
}