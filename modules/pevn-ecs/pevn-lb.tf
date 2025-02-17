# --- ALB ---

resource "aws_security_group" "http" {
  name_prefix = "http-sg-"
  description = "Allow all HTTP/HTTPS traffic from public"
  vpc_id      = var.ecs_vpc

  dynamic "ingress" {
    for_each = [80, 443]
    content {
      protocol    = "tcp"
      from_port   = 3000
      to_port     = 3000
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "backend" {
  name               = "backend-alb"
  load_balancer_type = "application"
  subnets            = [var.vpc_zone1_identifier,var.vpc_zone2_identifier]
  security_groups    = [aws_security_group.http.id]
}

resource "aws_lb_target_group" "backend" {
  name_prefix = "app-"
  vpc_id      = var.ecs_vpc
  protocol    = "HTTP"
  port        = 80
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/"
    port                = 80
    matcher             = 200
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.backend.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.id
  }
}