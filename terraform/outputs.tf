output "vpc_id" {
  description = "VPC ID used by the EKS cluster"
  value       = aws_vpc.main.id
}
