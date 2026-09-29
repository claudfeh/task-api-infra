output "app_url" {
  description = "Public URL of the deployed task-api"
  value       = "http://${aws_instance.app.public_ip}:8080"
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.app.id
}

output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.app.public_ip
}
