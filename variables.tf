variable "my_ip" {
  description = "Your static IP address (used for security group rules, etc.)"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "us-east-2"
}

variable "ip" {
  description = "IP address for your workstation"
  type        = string
  default     = "158.72.8.178"  
}

variable "instance_type" {
  description = "Type of EC2 instance to launch"
  type        = string
  default     = "t2.micro"
}
