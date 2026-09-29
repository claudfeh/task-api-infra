variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-2"
}

variable "project" {
  description = "Name prefix for all resources"
  type        = string
  default     = "task-api"
}

variable "instance_type" {
  description = "EC2 instance type (t3.micro is free-tier eligible)"
  type        = string
  default     = "t3.micro"
}

variable "ghcr_owner" {
  description = "GitHub username/owner of the task-api container image on GHCR"
  type        = string
  default     = "claudfeh"
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH into the instance. Tighten this to your own IP for real use."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
