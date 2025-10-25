# Application Load Balancer 
resource "aws_lb" "lb_sandbox" {
  name                       = "lb-sandbox"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.security_group_sandbox.id] // TODO: ECS用のセキュリティグループなので適当にする必要がある
  subnets                    = [aws_subnet.subnet_public_1a_sandbox.id, aws_subnet.subnet_public_1c_sandbox.id]
  enable_deletion_protection = false

  tags = {
    Name = "tag-sandbox"
  }
}

resource "aws_lb_listener" "lb_listener_sandbox" {
  load_balancer_arn = aws_lb.lb_sandbox.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group_sandbox.arn
  }
}

resource "aws_lb_target_group" "lb_target_group_sandbox" {
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc_sandbox.id
  target_type = "ip" # Fargateの場合、IPアドレスでターゲットを登録
}
