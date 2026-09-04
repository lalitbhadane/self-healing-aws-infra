resource "aws_security_group" "rds" {
  name        = "rds-security-group"
  description = "Allow PostgreSQL access from EC2 instances only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from EC2 instances"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.ec2_security_group_id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-security-group"
  }
}

resource "aws_db_instance" "main" {
  identifier     = "self-healing-db"
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.db_instance_class

  allocated_storage = var.db_allocated_storage

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az            = var.multi_az
  skip_final_snapshot = var.skip_final_snapshot
  publicly_accessible = false

  tags = {
    Name = "self-healing-db"
  }
}


