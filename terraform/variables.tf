variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "devopsdb"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "devopsadmin"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "app_instance_type" {
  description = "Application EC2 instance type"
  type        = string
  default     = "t3.micro"
}
