# Lecture du VPC par défaut (data source = jamais supprimé par Terraform)
data "aws_vpc" "main" {
  id = "vpc-0ebcdb39f7a526ef9"
}

# Internet Gateway existante du VPC par défaut
data "aws_internet_gateway" "igw" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

# Subnets publics (un par AZ)
resource "aws_subnet" "public" {
  count                   = length(var.azs)
  vpc_id                  = data.aws_vpc.main.id
  availability_zone       = var.azs[count.index]
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true
  tags = { Name = "xavier-td3-public-${count.index}" }
}

# Subnets privés web (un par AZ)
resource "aws_subnet" "web" {
  count                   = length(var.azs)
  vpc_id                  = data.aws_vpc.main.id
  availability_zone       = var.azs[count.index]
  cidr_block              = var.web_subnet_cidrs[count.index]
  map_public_ip_on_launch = false
  tags = { Name = "xavier-td3-web-${count.index}" }
}

# Subnets privés app (un par AZ)
resource "aws_subnet" "app" {
  count                   = length(var.azs)
  vpc_id                  = data.aws_vpc.main.id
  availability_zone       = var.azs[count.index]
  cidr_block              = var.app_subnet_cidrs[count.index]
  map_public_ip_on_launch = false
  tags = { Name = "xavier-td3-app-${count.index}" }
}

# Subnets privés data (un par AZ)
resource "aws_subnet" "data" {
  count                   = length(var.azs)
  vpc_id                  = data.aws_vpc.main.id
  availability_zone       = var.azs[count.index]
  cidr_block              = var.data_subnet_cidrs[count.index]
  map_public_ip_on_launch = false
  tags = { Name = "xavier-td3-data-${count.index}" }
}

# NAT Gateway une par AZ pour la haute disponibilité
resource "aws_eip" "nat" {
  count  = length(var.azs)
  domain = "vpc"
  tags   = { Name = "xavier-td3-eip-${count.index}" }
}

resource "aws_nat_gateway" "nat" {
  count         = length(var.azs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags          = { Name = "xavier-td3-nat-${count.index}" }
}

# Table de routage publique vers l'IGW existante
resource "aws_route_table" "public" {
  vpc_id = data.aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.igw.id
  }
  tags = { Name = "xavier-td3-rt-public" }
}

resource "aws_route_table_association" "public" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Tables de routage privées (une par AZ) vers la NAT Gateway
resource "aws_route_table" "private" {
  count  = length(var.azs)
  vpc_id = data.aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }
  tags = { Name = "xavier-td3-rt-private-${count.index}" }
}

resource "aws_route_table_association" "web" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.web[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "app" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "data" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.data[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
