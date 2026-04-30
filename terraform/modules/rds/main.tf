# rds.tf

# -----------------------------------------------
# Generate a random password for RDS
# -----------------------------------------------
resource "random_password" "db_password" {
  length  = 16
  special = false   # RDS has issues with some special chars
}

# -----------------------------------------------
# Store credentials in Secrets Manager
# -----------------------------------------------
resource "aws_secretsmanager_secret" "postgres" {
  name                    = "${var.project_name}/postgres"
  description             = "PostgreSQL credentials for ${var.project_name}"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "postgres" {
  secret_id = aws_secretsmanager_secret.postgres.id

  secret_string = jsonencode({
    DB_HOST     = aws_db_instance.postgres.address
    DB_PORT     = "5432"
    DB_NAME     = aws_db_instance.postgres.db_name
    DB_USER     = aws_db_instance.postgres.username
    DB_PASSWORD = random_password.db_password.result
  })
}

# -----------------------------------------------
# RDS subnet group
# -----------------------------------------------
resource "aws_db_subnet_group" "postgres" {
  name       = "${var.project_name}-postgres"
  subnet_ids = var.private_subnet_ids

  tags = { Name = "${var.project_name}-postgres" }
}

# -----------------------------------------------
# RDS security group
# -----------------------------------------------
resource "aws_security_group" "postgres" {
  name   = "${var.project_name}-prod-postgres-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.sg.node_sg_id]  # only EKS nodes
    description     = "EKS nodes to RDS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-prod-postgres-sg" }
}

# -----------------------------------------------
# RDS instance
# -----------------------------------------------
resource "aws_db_instance" "postgres" {
  identifier        = "${var.project_name}-postgres"
  engine            = "postgres"
  engine_version    = "16.2"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = "${var.project_name}_db"
  username = "gumgum_user"
  password = random_password.db_password.result

  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.postgres.id]

  multi_az               = false   # set true for prod HA
  publicly_accessible    = false
  skip_final_snapshot    = true    # set false in real prod

  tags = { Name = "${var.project_name}-prod-postgres"}
}

# -----------------------------------------------
# Output secret ARN — needed for ESO IRSA policy
# -----------------------------------------------
output "postgres_secret_arn" {
  value = aws_secretsmanager_secret.postgres.arn
}