output "alb_dns_name" {
  value       = aws_lb.main.dns_name
  description = "WordPress site URL"
}

output "rds_endpoint" {
  value       = aws_db_instance.wordpress.address
  description = "RDS MySQL endpoint"
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.media.bucket
  description = "S3 media bucket"
}

output "asg_name" {
  value       = aws_autoscaling_group.wordpress.name
  description = "Auto Scaling Group name"
}