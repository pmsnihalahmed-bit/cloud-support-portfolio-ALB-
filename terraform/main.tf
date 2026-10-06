resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "VPC-main" }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = { Name = "Public-A" }
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = { Name = "Public-B" }
}
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = { Name = "Private-A" }
}
resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = { Name = "Private-B" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "Main-IGW" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "public-RT" }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }

  tags = { Name = "private-a-rt" }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_b.id
  }

  tags = { Name = "private-b-rt" }
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_b.id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  vpc_endpoint_type = "Gateway"

  service_name = "com.amazonaws.${var.aws_region}.s3"

  route_table_ids = [aws_route_table.private_a.id, aws_route_table.private_b.id]
}

resource "aws_eip" "nat_a" {
  domain = "vpc"

  tags = { Name = "eip-nat-az-a" }
}

resource "aws_eip" "nat_b" {
  domain = "vpc"

  tags = { Name = "eip-nat-az-b" }
}
resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.public_a.id

  tags = { Name = "nat-gateway-az-a" }
}
resource "aws_nat_gateway" "nat_b" {
  allocation_id = aws_eip.nat_b.id
  subnet_id     = aws_subnet.public_b.id

  tags = { Name = "nat-gateway-az-b" }
}

resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "managed_key" {
  key_name   = "terraform-maanged-key"
  public_key = tls_private_key.pk.public_key_openssh
}

resource "aws_security_group" "pvt_sg" {
  vpc_id = aws_vpc.main.id

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = { Name = "pvt-sg" }
}

resource "aws_instance" "ec2_a" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private_a.id
  vpc_security_group_ids      = [aws_security_group.pvt_sg.id]
  key_name                    = aws_key_pair.managed_key.key_name
  associate_public_ip_address = false

  root_block_device  {
    volume_size            = 10
    volume_type            = "gp3"
    delete_on_termination = true
  }

  tags = { Name = "EC2-A" }
}

resource "aws_instance" "ec2_b" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private_b.id
  vpc_security_group_ids      = [aws_security_group.pvt_sg.id]
  key_name                    = aws_key_pair.managed_key.key_name
  associate_public_ip_address = false

  root_block_device  {
    volume_size            = 10
    volume_type            = "gp3"
    delete_on_termination = true
  }

  tags = { Name = "EC2-B" }
}

