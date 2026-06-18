resource "aws_security_group" "alb_public" {
  name        = "xavier-td3-sg-alb-public"
  description = "HTTP depuis Internet"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description = "HTTP depuis Internet"
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

  tags = { Name = "xavier-td3-sg-alb-public" }
}

resource "aws_security_group" "web" {
  name        = "xavier-td3-sg-web"
  description = "HTTP depuis ALB public uniquement"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description     = "HTTP depuis ALB public"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_public.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "xavier-td3-sg-web" }
}

resource "aws_security_group" "alb_internal" {
  name        = "xavier-td3-sg-alb-internal"
  description = "HTTP depuis le tier web uniquement"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description     = "HTTP depuis tier web"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "xavier-td3-sg-alb-internal" }
}

resource "aws_security_group" "app" {
  name        = "xavier-td3-sg-app"
  description = "HTTP depuis ALB interne uniquement"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description     = "HTTP depuis ALB interne"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_internal.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "xavier-td3-sg-app" }
}

resource "aws_security_group" "rds" {
  name        = "xavier-td3-sg-rds"
  description = "PostgreSQL depuis tier app uniquement"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description     = "PostgreSQL depuis tier app"
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

  tags = { Name = "xavier-td3-sg-rds" }
}
