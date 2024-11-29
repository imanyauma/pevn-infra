output "rds_username" {
  value = aws_rds_cluster.default.master_username
}

output "rds_password" {
  value = aws_rds_cluster.default.master_password
}

output "rds_database" {
  value = aws_rds_cluster.default.database_name
}