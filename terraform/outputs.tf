output "instance_a_id" {
  value = aws_instance.ec2_a.id
}

output "instance_b_id" {
  value = aws_instance.ec2_b.id
}
output "alb_dns_name" {
value = aws_lb.external_lb.dns_name
}

output "s3_bucket_name" {
value = aws_s3_bucket.app_storage.bucket
}
