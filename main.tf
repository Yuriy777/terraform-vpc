resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "${terraform.workspace}-vpc"
  }
}

resource "aws_subnet" "public-sbn" {
  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, 1)

  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone

  tags = {
    Name = "${terraform.workspace}-public-sbn"
  }
}
resource "aws_subnet" "private-sbn" {
  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, 2)

  availability_zone = var.availability_zone

  tags = {
    Name = "${terraform.workspace}-private-sbn"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${terraform.workspace}-igw"
  }
}

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${terraform.workspace}-public-rt"
  }
}

resource "aws_route_table_association" "public-route-association" {
  subnet_id      = aws_subnet.public-sbn.id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_eip" "main" {
  domain = "vpc"

  tags = {
    Name = "${terraform.workspace}-eip"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.main.id
  subnet_id     = aws_subnet.public-sbn.id

  tags = {
    Name = "${terraform.workspace}-NAT"
  }
}

resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${terraform.workspace}-private-rt"
  }
}

resource "aws_route_table_association" "private-route-association" {
  subnet_id      = aws_subnet.private-sbn.id
  route_table_id = aws_route_table.private-rt.id
}

resource "aws_security_group" "allow-http-sg" {
  name        = "allow_http"
  description = "Allow traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${terraform.workspace}-allow_http-sg"
  }
}

resource "aws_security_group" "allow-ssh-sg" {
  name        = "allow_ssh"
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "ssh from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${terraform.workspace}-allow_ssh-to-public-sg"
  }
}

resource "aws_security_group" "allow-ssh-private-sg" {
  name        = "allow_ssh_private"
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "ssh from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  tags = {
    Name = "${terraform.workspace}-allow_ssh-to-private-sg"
  }
}

data "aws_key_pair" "main" {
  key_name   = "terraform-test"
  include_public_key = true
}

resource "aws_instance" "server" {
  ami           = var.ami-id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public-sbn.id
  key_name = data.aws_key_pair.main.key_name
  depends_on = [aws_security_group.allow-http-sg]

  vpc_security_group_ids = [
    aws_security_group.allow-http-sg.id,
    aws_security_group.allow-ssh-sg.id
  ]

  user_data = file("user-data.sh")

  tags = {
    Name = "${terraform.workspace}-public-server-instance"
  }
}

resource "aws_instance" "private-server" {
  ami           = var.ami-id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private-sbn.id
  key_name = data.aws_key_pair.main.key_name

  vpc_security_group_ids = [
    aws_security_group.allow-ssh-private-sg.id
  ]

  tags = {
    Name = "${terraform.workspace}-private-server-instance"
  }
}