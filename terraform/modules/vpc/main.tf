/**********************************************
 This will deploy one vpc
   - public subnet/private subnets based on variables
   - igw
   - nat-gateway
   - associated route tables
**********************************************/

resource "aws_vpc" "vpc" {
   cidr_block           = "${var.vpc_cidr}"
   enable_dns_hostnames = "${var.enable_dns_hostnames}"
   tags = {
        Name        = "${var.vpc_name}"
        environment = "${var.environment}"
   }
}

/* Internet-Gateways */
resource "aws_internet_gateway" "igw" {
   vpc_id = "${aws_vpc.vpc.id}"
   tags = {
        Name         = "igw-pub-sub"
        environment  = "${var.environment}"
   }
}

/***** Routing information public subnet ***************/
resource "aws_route_table" "pub_rtb" {
   vpc_id = "${aws_vpc.vpc.id}"
   route {
     cidr_block = "0.0.0.0/0"
     gateway_id ="${aws_internet_gateway.igw.id}"
   }
   tags = {
     Name        = "Public-RTB"
     environment = "${var.environment}"
   }
}

resource "aws_route_table_association" "a-pub-sub" {
   count          =  "${length(var.public_sub_cidr)}"
   subnet_id      = "${element(aws_subnet.public-subnet.*.id,count.index)}"
   route_table_id = "${element(aws_route_table.pub_rtb.*.id,count.index)}"
}

/**************** Public-subnet **********/
resource "aws_subnet" "public-subnet" {
   count             = "${length(var.public_sub_cidr)}"
   availability_zone = "${element(var.azs,count.index)}"
   cidr_block        = "${var.public_sub_cidr[count.index]}"
   vpc_id            = "${aws_vpc.vpc.id}"
   tags = {
        Name        = "Public_Subnet-${count.index}"
        environment = "${var.environment}"
   }
}

/********************Nat-Gateway **********************/
resource "aws_nat_gateway" "ngw" {
    allocation_id = "${aws_eip.nat.id}"
    subnet_id     = "${aws_subnet.public-subnet.*.id[0]}"
    depends_on    = ["aws_internet_gateway.igw"]
}

resource "aws_eip" "nat"{
   vpc = true
}


/********* Private-subnet ***************/

resource "aws_subnet" "private-subnet" {
   count             = "${length(var.private_sub_cidr)}"
   availability_zone = "${element(var.azs,count.index)}"
   cidr_block        = "${var.private_sub_cidr[count.index]}"
   vpc_id            = "${aws_vpc.vpc.id}"
   tags = {
        Name        = "Private_Subnet-${count.index}"
        environment = "${var.environment}"
   }
   depends_on = ["aws_nat_gateway.ngw"]
}

/***** Routing information private subnet ************/

resource "aws_route_table" "pri_rtb" {
   vpc_id = "${aws_vpc.vpc.id}"
   route {
     cidr_block = "0.0.0.0/0"
     gateway_id ="${aws_nat_gateway.ngw.id}"
   }
   tags = {
     Name        = "Private-RTB"
     environment = "${var.environment}"
   }
}

resource "aws_route_table_association" "a-priv-sub" {
   count          = "${length(var.private_sub_cidr)}"
   subnet_id      =  "${element(aws_subnet.private-subnet.*.id,count.index)}"
   route_table_id = "${element(aws_route_table.pri_rtb.*.id,count.index)}"
}



resource "null_resource" "module_dependency" {
   depends_on = [
        "aws_vpc.vpc",
        "aws_subnet.public-subnet",
        "aws_subnet.private-subnet",
        "aws_internet_gateway.igw",
        "aws_route_table.pub_rtb",
        "aws_route_table_association.a-pub-sub",
        "aws_route_table.pri_rtb",
        "aws_route_table_association.a-priv-sub",
        "aws_internet_gateway.igw",
        "aws_eip.nat"
   ]
}
