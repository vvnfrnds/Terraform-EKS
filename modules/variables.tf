variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "availability_zone" {
    description = "Availability zone for the subnet"
    type        = list(string)
}

variable "private_subnet_cidr" {
    description = "CIDR block for private subnet"
    type        = list(string)
}

variable "public_subnet_cidr" {
    description = "CIDR block for public subnet"
    type        = list(string)
}

