resource "aws_vpc" "main" {                         //Create VPC
    cidr_block = var.vpc_cidr
    enable_dns_support = true
    enable_dns_hostnames = true

    tags = {
        Name = "${var.cluster_name}-vpc"
        "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    }
}

resource "aws_subnet" "private" {                   //Create Private Subnet         
    count = length(var.private_subnet_cidrs)
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_subnet_cidrs[count.index]
    availability_zone = var.availability_zones[count.index]
    
    tags = {
        Name                                           = "${var.cluster_name}-private-${count.index + 1}"
        "kubernetes.io/cluster/${var.cluster_name}"    = "shared"
        "kubernetes.io/role/internal-elb"              = "1"
    }  
}


resource "aws_subnet" "public" {                    //Create Public Subnet 
    count = length(var.public_subnet_cidrs)
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnet_cidrs[count.index]
    availability_zone = var.availability_zones[count.index]

    map_public_ip_on_launch = true          //Necessary Line
    
    tags = {
        Name                                           = "${var.cluster_name}-public-${count.index + 1}"
        "kubernetes.io/cluster/${var.cluster_name}"    = "shared"
        "kubernetes.io/role/elb"                       = "1"
    }    
}

resource "aws_internet_gateway" "main" {            //Create Internet Gateway for VPC
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "${var.cluster_name}-igw"
    }
}

resource "aws_eip" "nat" {
  count = length(var.public_subnet_cidrs)
  domain = "vpc"

  tags = {
    Name = "${var.cluster_name}-nat-${count.index + 1}"
  }
}

resource "aws_route_table" "public" {               //Create Route Table for Public Subnet
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
    }

    tags = {
        Name = "${var.cluster_name}-public"
    }
}

resource "aws_route_table_association" "public" {       //Create Route Table Association for Public Subnet
    count = length(var.public_subnet_cidrs)
    subnet_id      = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.public.id
}

resource "aws_nat_gateway" "main" {                  //Create NAT Gateway for Private Subnet
    count = length(var.public_subnet_cidrs)
    allocation_id = aws_eip.nat[count.index].id
    subnet_id     = aws_subnet.public[count.index].id

    tags = {
        Name = "${var.cluster_name}-nat-${count.index + 1}"
    }  
}

resource "aws_route_table" "private" {
    count = length(var.private_subnet_cidrs)
    vpc_id = aws_vpc.main.id

    route = {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.name[count.index].id
    }

    tags = {
        Name = "${var.cluster_name}-private-${count.index + 1}"
    }
}


resource "aws_route_table_association" "private" {
    count = length(var.private_subnet_cidrs)
    subnet_id      = aws_subnet.private[count.index].id
    route_table_id = aws_route_table.private[count.index].id
}

