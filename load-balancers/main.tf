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
resource "aws_lb_target_group" "main" {
  name     = "${var.name}-${var.env}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

resource "aws_lb_target_group_attachment" "main" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = var.instance_id
  port             = 80
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_alb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
