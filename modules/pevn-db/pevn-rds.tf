#Create RDS Cluster with name service-user-db
resource "aws_rds_cluster" "default" {
  cluster_identifier      = "service-user-db"
  engine                  = "aurora-mysql"
  engine_version          = "5.7.mysql_aurora.2.11.2"
  db_subnet_group_name    = aws_db_subnet_group.service-user-sg.name
  database_name           = "tutorials"
  master_username         = "admin"
  master_password         = random_password.master.result
  skip_final_snapshot     = true
  vpc_security_group_ids = [ var.rds-sg ]
}

#Setting RDS Cluster Instance
resource "aws_rds_cluster_instance" "cluster_instances" {
  count              = 1
  identifier         = "service-user-db-${count.index}"
  cluster_identifier = aws_rds_cluster.default.id
  instance_class     = "db.t3.small"
  engine             = aws_rds_cluster.default.engine
  engine_version     = aws_rds_cluster.default.engine_version
}


resource "aws_db_subnet_group" "service-user-sg" {
  name       = "service-user-sg"
  subnet_ids = [var.subnet_id_a, var.subnet_id_b]
  tags = {
    Name = "BE Course DB"
  }
}

# Set random password for admin
resource "random_password" "master"{
  length           = 16
  special          = true
  override_special = "_!%^"
}