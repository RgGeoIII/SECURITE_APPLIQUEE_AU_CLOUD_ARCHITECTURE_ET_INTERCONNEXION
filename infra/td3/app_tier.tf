data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_lb" "internal" {
  name               = "xavier-td3-alb-internal"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_internal.id]
  subnets            = aws_subnet.app[*].id

  tags = { Name = "xavier-td3-alb-internal" }
}

resource "aws_lb_target_group" "app" {
  name     = "xavier-td3-tg-app"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.main.id

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = { Name = "xavier-td3-tg-app" }
}

resource "aws_lb_listener" "internal_http" {
  load_balancer_arn = aws_lb.internal.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_instance" "app" {
  count         = length(var.azs)
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  key_name      = var.key_name
  subnet_id     = aws_subnet.app[count.index].id

  vpc_security_group_ids = [aws_security_group.app.id]

  user_data = templatefile("${path.module}/app/user_data.sh.tpl", {
    db_host     = "td-ipssi-rds-v2.clqqieekmedc.eu-west-3.rds.amazonaws.com"
    db_name     = "mydb"
    db_user     = "adminipssidb"
    db_password = "kSzSWSJVImXblGzX"
  })

  tags = { Name = "xavier-td3-app-${count.index}" }
}

resource "aws_lb_target_group_attachment" "app" {
  count            = length(var.azs)
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app[count.index].id
  port             = 80
}
