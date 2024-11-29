output "rds_password" {
  value = module.pevn-db.rds_password
  sensitive = true
}

output "rds_username" {
  value = module.pevn-db.rds_username
}

output "rds_database" {
  value = module.pevn-db.rds_database
}

output "s3_web_domain" {
  value = module.pevn-s3-cloudfront.s3_web_domain
}

output "cloudfront_domain" {
  value = module.pevn-s3-cloudfront.cloudfront_domain
}

output "bastion_host_ip" {
  value = module.bastion-host.bastion_public_ip
}

output "ecs_alb_name" {
  value = module.pevn_ecs.ecs_cluster_name
}