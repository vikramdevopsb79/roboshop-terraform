resource "aws_security_group" "main" {
  name        = "${var.name}-${var.env}-sg"
  description = "${var.name}-${var.env}-sg"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.name}-${var.env}-lb-sg"
  }
}
resource "aws_alb" "main" {
  name = "${var.name}-${var.env}-lb"
  internal = var.internal
  load_balancer_type = var.load_balancer_type
  security_groups = [aws_security_group.main.id]
  subnets = var.subnet_ids
  tags = {
    Environment = "${var.name}-${var.env}-lb"
  }

}