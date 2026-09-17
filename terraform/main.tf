# ---------------------------------------------------------
# VPC
# ---------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "devops-assignment-vpc"
  }
}

# ---------------------------------------------------------
# Public Subnets
# ---------------------------------------------------------

resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "devops-public-${count.index + 1}"
  }
}

# ---------------------------------------------------------
# Private Subnets
# ---------------------------------------------------------

resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 11}.0/24"
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "devops-private-${count.index + 1}"
  }
}

# ---------------------------------------------------------
# Internet Gateway
# ---------------------------------------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "devops-assignment-igw"
  }
}

# ---------------------------------------------------------
# Public Route Table
# ---------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "devops-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ---------------------------------------------------------
# NAT Gateway
# ---------------------------------------------------------

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "devops-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  depends_on = [
    aws_internet_gateway.main
  ]

  tags = {
    Name = "devops-nat-gateway"
  }
}

# ---------------------------------------------------------
# Private Route Table
# ---------------------------------------------------------

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "devops-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  count = 2

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# ---------------------------------------------------------
# Security Group - ALB
# ---------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "devops-alb-sg"
  description = "Security group for application load balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-alb-sg"
  }
}

# ---------------------------------------------------------
# Security Group - Application
# ---------------------------------------------------------

resource "aws_security_group" "app" {
  name        = "devops-app-sg"
  description = "Security group for application EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Application traffic from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-app-sg"
  }
}

# ---------------------------------------------------------
# Security Group - RDS
# ---------------------------------------------------------

resource "aws_security_group" "rds" {
  name        = "devops-rds-sg"
  description = "Security group for PostgreSQL RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from application"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-rds-sg"
  }
}

# ---------------------------------------------------------
# RDS Subnet Group
# ---------------------------------------------------------

resource "aws_db_subnet_group" "postgres" {
  name = "devops-postgres-subnet-group"

  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "devops-postgres-subnet-group"
  }
}

# ---------------------------------------------------------
# Ubuntu AMI
# ---------------------------------------------------------

data "aws_ami" "ubuntu" {
  most_recent = true

  owners = [
    "099720109477"
  ]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# ---------------------------------------------------------
# IAM Role - Application EC2
# ---------------------------------------------------------

resource "aws_iam_role" "ec2" {
  name = "devops-app-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}



resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "devops-app-ec2-profile"
  role = aws_iam_role.ec2.name
}
resource "aws_key_pair" "deploy" {
  key_name   = "devops-deploy-key"
  public_key = file("${path.module}/../devops-deploy-key.pub")
}
# ---------------------------------------------------------
# ECR
# ---------------------------------------------------------

resource "aws_ecr_repository" "app" {
  name                 = "devops-app"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "devops-app"
  }
}

# ---------------------------------------------------------
# Production EC2
# ---------------------------------------------------------

resource "aws_instance" "app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.app_instance_type
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.app.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name
  key_name               = aws_key_pair.deploy.key_name

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y openjdk-17-jre
  EOF

  tags = {
    Name        = "devops-app-server"
    Environment = "production"
  }
}
# ------------------------------------------------------
# Staging EC2
# ---------------------------------------------------------

resource "aws_instance" "staging" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.app_instance_type
  subnet_id              = aws_subnet.private[1].id
  vpc_security_group_ids = [aws_security_group.app.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name
  key_name               = aws_key_pair.deploy.key_name

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y docker.io
    systemctl enable docker
    systemctl start docker
  EOF

  tags = {
    Name        = "devops-staging-server"
    Environment = "staging"
  }
}

# ---------------------------------------------------------
# RDS PostgreSQL
# ---------------------------------------------------------

resource "aws_db_instance" "postgres" {
  identifier = "devops-postgres"

  engine         = "postgres"
  engine_version = "16"

  instance_class = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 50
  storage_type          = "gp3"

  db_name  = var.db_name
  username = var.db_username

  manage_master_user_password = true

  db_subnet_group_name = aws_db_subnet_group.postgres.name

  vpc_security_group_ids = [
    aws_security_group.rds.id
  ]

  publicly_accessible = false

  backup_retention_period = 7

  skip_final_snapshot = true

  deletion_protection = false

  tags = {
    Name = "devops-postgres"
  }
}

# ---------------------------------------------------------
# Application Load Balancer
# ---------------------------------------------------------

resource "aws_lb" "app" {
  name               = "devops-app-alb"
  internal           = false
  load_balancer_type = "application"

  subnets = aws_subnet.public[*].id

  security_groups = [
    aws_security_group.alb.id
  ]

  tags = {
    Name = "devops-app-alb"
  }
}

# ---------------------------------------------------------
# ALB Target Group
# ---------------------------------------------------------

resource "aws_lb_target_group" "app" {
  name     = "devops-app-tg"
  port     = 8080
  protocol = "HTTP"

  vpc_id = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/actuator/health"
    port                = "8080"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }

  tags = {
    Name = "devops-app-tg"
  }
}

# ---------------------------------------------------------
# ALB Target - Production
# ---------------------------------------------------------

resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app.id
  port             = 8080
}

# ---------------------------------------------------------
# ALB Listener
# ---------------------------------------------------------

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type = "forward"

    target_group_arn = aws_lb_target_group.app.arn
  }

}

