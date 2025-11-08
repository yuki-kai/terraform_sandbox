# VPC
resource "aws_vpc" "vpc_sandbox" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "tag-sandbox"
  }
}

# インターネットゲートウェイ
resource "aws_internet_gateway" "internet_gateway_sandbox" {
  vpc_id = aws_vpc.vpc_sandbox.id

  tags = {
    Name = "tag-sandbox"
  }
}

# ルートテーブル
resource "aws_route_table" "route_table_sandbox" {
  vpc_id = aws_vpc.vpc_sandbox.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway_sandbox.id
  }

  tags = {
    Name = "tag-sandbox"
  }
}


# サブネット
resource "aws_subnet" "subnet_public_1a_sandbox" {
  vpc_id                  = aws_vpc.vpc_sandbox.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "tag-sandbox"
  }
}
resource "aws_subnet" "subnet_public_1c_sandbox" {
  vpc_id                  = aws_vpc.vpc_sandbox.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = false

  tags = {
    Name = "tag-sandbox"
  }
}

# ルートテーブルとサブネットの関連付け1
resource "aws_route_table_association" "route_table_association_a_sandbox" {
  subnet_id      = aws_subnet.subnet_public_1a_sandbox.id
  route_table_id = aws_route_table.route_table_sandbox.id
}
resource "aws_route_table_association" "route_table_association_c_sandbox" {
  subnet_id      = aws_subnet.subnet_public_1c_sandbox.id
  route_table_id = aws_route_table.route_table_sandbox.id
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
  route_table_ids   = [aws_route_table.route_table_sandbox.id] # プライベートサブネットのルートテーブル
  tags              = { Name = "s3-gateway-endpoint" }
}
