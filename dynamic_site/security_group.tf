# セキュリティグループ
resource "aws_security_group" "security_group_sandbox" {
  vpc_id = aws_vpc.vpc_sandbox.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg"
  description = "Allow traffic from ALB only"
  vpc_id      = aws_vpc.vpc_sandbox.id

  # ALB からの 3000/tcp のみ許可（source_security_group_id を使用）
  ingress {
    description      = "Allow ALB to reach container port 3000"
    from_port        = 3000
    to_port          = 3000
    protocol         = "tcp"
    security_groups  = [aws_security_group.security_group_sandbox.id]
    self             = false
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    cidr_blocks      = []
  }

  # 必要に応じて、タスクが外部にアクセスするための egress を許可
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-sg"
  }
}
