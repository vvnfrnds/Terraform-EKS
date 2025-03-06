variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "availability_zones" {
    description = "Availability zone for the subnet"
    type        = list(string)
}

variable "private_subnet_cidrs" {
    description = "CIDR block for private subnet"
    type        = list(string)
}

variable "public_subnet_cidrs" {
    description = "CIDR block for public subnet"
    type        = list(string)
  
}

variable "cluster_name" {
    description = "Name of the EKS cluster"
    type        = string
  
}

