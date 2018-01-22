/*
   Variables for ECS_CLUSTER
*/


variable "keypair_public_key" {}
variable "vpc-id" {}
variable "region" {}
variable "aws_key_name" {}
variable "environment" {}
variable "ingress_instance_type" {}
variable "bastion_sg_id" {}
variable "ami_owner_name" {}
variable "ami_name_regex" {}
variable "vpc_cidr" {}

// ASG
variable "kong_asg_max_size" {}
variable "kong_asg_min_size" {}
variable "kong_asg_desired_size" {}

variable "load_balancers" {
    default = []
}


variable "public_subnet_ids" {
   default = []
}

variable "dependency_id" {
  default = ""
}


variable "public_sub_cidr" {
     default = []
}

variable "private_sub_cidr" {
     default = []
}

variable "control_cidr" {
}
