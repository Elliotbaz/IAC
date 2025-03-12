# bastion server
resource "aws_instance" "dcv-bastion" {
  ami = "ami-066784287e358dad1"
  instance_type = "t2.micro"
  key_name = local.ssh_key_name
  subnet_id = local.public_subnets[0]
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.dcv-bastion.id]
  tags = merge(local.common_tags, {
    Name = "${local.prefix}-dcv-bastion"
  })
}

# security group
resource "aws_security_group" "dcv-bastion" {
  name = "${local.prefix}-dcv-bastion"
  vpc_id = local.vpc_id
  tags = local.common_tags
}

resource "aws_security_group_rule" "dcv-bastion-ssh-ingress" {
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  security_group_id = aws_security_group.dcv-bastion.id
  cidr_blocks = ["0.0.0.0/0"]
}

# use the dcv server security grouip id output to create an ingress rule for the bastion
resource "aws_security_group_rule" "dcv-bastion-dcv-ingress" {
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  security_group_id = local.dcv_server_instance_sg
  source_security_group_id = aws_security_group.dcv-bastion.id
}

resource "aws_security_group_rule" "dcv-bastion-ssh-egress" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  security_group_id = aws_security_group.dcv-bastion.id
  cidr_blocks = ["0.0.0.0/0"]
  
}
