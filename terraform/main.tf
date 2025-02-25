# Create VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# Create Public Subnet (for NAT Gateway)
resource "aws_subnet" "public_subnet_az1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_subnet_az2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.11.0/24"
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = true
}

# Create NAT Gateway
resource "aws_eip" "nat_eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_az1.id
}


# Public Subnet Route Table for Internet Gateway
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# Associate Route Table with Public Subnet for NAT Gateway
resource "aws_route_table_association" "public_route_table_association_az1" {
  subnet_id      = aws_subnet.public_subnet_az1.id
  route_table_id = aws_route_table.public_route_table.id
}


# Create Route Table for Private Subnets
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id
}

# Create Route for Private Subnets to use NAT Gateway
resource "aws_route" "private_nat_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

# Associate Route Table with Private Subnets
resource "aws_route_table_association" "private_route_table_association_db" {
  subnet_id      = aws_subnet.db_subnet_private.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_route_table_association_app_az1" {
  subnet_id      = aws_subnet.app_subnet_private_az1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_route_table_association_app_az2" {
  subnet_id      = aws_subnet.app_subnet_private_az2.id
  route_table_id = aws_route_table.private_route_table.id
}


# Subnets for App Server and DB
resource "aws_subnet" "app_subnet_private_az1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = false
}

resource "aws_subnet" "app_subnet_private_az2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = false
}

resource "aws_subnet" "db_subnet_private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.5.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = false
}

# EC2 Instance for MySQL DB (Static Private IP: 10.0.5.10)
resource "aws_instance" "chatwtf_db" {
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  key_name               = var.key_name
  subnet_id             = aws_subnet.db_subnet_private.id
  private_ip            = "10.0.5.10"  # Changed to a valid private IP in the subnet
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  associate_public_ip_address = false

  tags = {
    Name = "yhsllm-chatwtf-db"
  }

  user_data = <<EOF
#!/bin/bash
echo "Executing user data" >/home/ubuntu/userdata.txt
sleep 60
apt-get update -y
apt-get install -y mysql-server git php php-mysql docker.io docker-doc docker-compose docker-compose-v2 containerd runc iotop iftop net-tools nmap htop nano elinks lynx locate
service mysql start
git clone ${var.github_repo} /tmp/llm
cd /tmp/llm
mysql -u root -e "CREATE DATABASE chatwtf;"
mysql -u root -e "CREATE USER 'user123'@'%' IDENTIFIED BY 'password123';"
mysql -u root -e "GRANT ALL ON chatwtf.* TO 'user123'@'%';"
mysql -u root chatwtf < /tmp/llm/db/mysql.sql
mysql -u root -e "flush privileges;"
EOF

}

# Security Group for DB
resource "aws_security_group" "db_sg" {
  name        = "yhsllm-db-sg"
  description = "DB server security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.app_subnet_private_az1.cidr_block, aws_subnet.app_subnet_private_az2.cidr_block]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.app_subnet_private_az1.cidr_block, aws_subnet.app_subnet_private_az2.cidr_block]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.app_subnet_private_az1.cidr_block, aws_subnet.app_subnet_private_az2.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# App Server Security Group
resource "aws_security_group" "ec2_sg" {
  name        = "yhsllm-app-sg"
  description = "App server security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.app_subnet_private_az1.cidr_block, aws_subnet.app_subnet_private_az2.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Elastic Load Balancer
resource "aws_lb" "app_lb" {
  name               = "yhsllm-app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ec2_sg.id]
  subnets            = [aws_subnet.public_subnet_az1.id, aws_subnet.public_subnet_az2.id]
  enable_deletion_protection = false

  tags = {
    Name = "yhsllm-app-lb"
  }
}

# Load Balancer Listener and Target Group
resource "aws_lb_target_group" "app_target_group" {
  name        = "yhsllm-app-target-group"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 5
    interval            = 300
    path                = "/"  # Update if needed
    protocol            = "HTTP"
    timeout             = 30
  }
}

resource "aws_lb_listener" "app_lb_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_target_group.arn
  }
}

# Attach App Server EC2 to Target Group (via Target Group Attachment)
resource "aws_lb_target_group_attachment" "app_server_attachment" {
  target_group_arn = aws_lb_target_group.app_target_group.arn
  target_id        = aws_instance.app_server.id
  port             = 8080  # The app server listens on port 8080
}

# Create VPC Endpoint for EC2 Instance Connect
resource "aws_ec2_instance_connect_endpoint" "ec2_connect_endpoint" {
  subnet_id         = aws_subnet.app_subnet_private_az1.id
  security_group_ids = [aws_security_group.ec2_sg.id]  # Allowing access via the same security group for the instance
  preserve_client_ip = false
  tags = {
    Name = "ys-ec2-instance-connect-endpoint"
  }
}

# App Server EC2 Instance
resource "aws_instance" "app_server" {
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  key_name               = var.key_name
  subnet_id             = aws_subnet.app_subnet_private_az1.id
  private_ip            = "10.0.2.10"
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]  # Correct security group reference
  associate_public_ip_address = false

  tags = {
    Name = "yhsllm-app-server"
  }

  user_data = <<EOF
#!/bin/bash
echo "Executing user data" >/home/ubuntu/userdata.txt
sleep 60
apt-get update -y
apt-get install -y git php docker.io docker-doc docker-compose docker-compose-v2 containerd runc iotop iftop net-tools nmap htop nano elinks lynx locate
git clone ${var.github_repo} /tmp/llm
cd /tmp/llm 
docker build -t chatwtf .
docker run -d -p 8080:80 chatwtf
EOF

}
