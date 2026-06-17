resource "aws_subnet" "private" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = "172.31.${100 + var.student_id}.0/24"
  availability_zone = "eu-west-3a"

  tags = {
    Name = "${local.prefix}-private"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${local.prefix}-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = data.aws_subnet.public_a.id

  tags = {
    Name = "${local.prefix}-nat"
  }
}

resource "aws_route_table" "private" {
  vpc_id = data.aws_vpc.default.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${local.prefix}-rt-private"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}