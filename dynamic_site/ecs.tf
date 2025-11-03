# ECS クラスター
resource "aws_ecs_cluster" "ecs_cluster_sandbox" {
  name = "ecs-cluster-sandbox"
}

# ECS タスク定義
resource "aws_ecs_task_definition" "ecs_task_definition_sandbox" {
  family                   = "terraform-sandbox"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512

  // ECRからnextjsのイメージを取得
  container_definitions = jsonencode([
    {
      name  = "terraform-sandbox"
      image = "144560605492.dkr.ecr.ap-northeast-1.amazonaws.com/nextjs:latest",
      portMappings = [
        {
          containerPort = 3000
          "protocol"    = "tcp",
        }
      ],
    }
  ])
  runtime_platform {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }
}

# ECS サービス
resource "aws_ecs_service" "ecs_service_sandbox" {
  name            = "terraform-ecs-service"
  cluster         = aws_ecs_cluster.ecs_cluster_sandbox.id
  task_definition = aws_ecs_task_definition.ecs_task_definition_sandbox.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.subnet_public_1a_sandbox.id, aws_subnet.subnet_public_1c_sandbox.id]
    security_groups = [aws_security_group.ecs_sg.id]
    # VPCエンドポイント経由でECRをpullする
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.lb_target_group_sandbox.arn
    container_name   = "terraform-sandbox" // aws_ecs_task_definitionのcontainer_definitionsのnameと同じであること
    container_port   = 3000
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_role_policy,
  ]
}

# VPCエンドポイント経由でECRをpullする
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.vpc_sandbox.id
  service_name        = "com.amazonaws.ap-northeast-1.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids = [
    aws_subnet.subnet_public_1a_sandbox.id,
    aws_subnet.subnet_public_1c_sandbox.id,
  ]
  security_group_ids = [aws_security_group.security_group_sandbox.id]
  tags = {
    Name = "ecr-api-endpoint"
  }
}

# dockerコマンドを実行するためのエンドポイント
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.vpc_sandbox.id
  service_name        = "com.amazonaws.ap-northeast-1.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids = [
    aws_subnet.subnet_public_1a_sandbox.id,
    aws_subnet.subnet_public_1c_sandbox.id,
  ]
  security_group_ids = [aws_security_group.security_group_sandbox.id]
  tags = {
    Name = "ecr-dkr-endpoint"
  }
}

# コンテナイメージをpullするためのエンドポイント
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.vpc_sandbox.id
  service_name      = "com.amazonaws.ap-northeast-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.route_table_sandbox.id]  # プライベートサブネットのルートテーブル
  tags = { Name = "s3-gateway-endpoint" }
}
