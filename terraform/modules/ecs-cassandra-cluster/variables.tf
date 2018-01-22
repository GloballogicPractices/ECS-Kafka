/*
   Variables for ECS_CLUSTER
*/


variable "keypair_public_key" {}
variable "vpc-id" {}
variable "region" {}
variable "aws_key_name" {}
variable "environment" {}
variable "cassandra_instance_type" {}
variable "control_cidr" {}
variable "bastion_sg_id" {}
#variable "vpc_sg_id" {}
variable "ami_owner_name" {}
variable "ami_name_regex" {}
variable "vpc_cidr" {}

// EBS
variable "cass_ebs_dev_name" {}
variable "cass_ebs_vol_type" {}
variable "cass_ebs_vol_size" {}
variable "cass_data_dir" {}

// ASG
variable "cassandra_asg_max_size" {}
variable "cassandra_asg_min_size" {}
variable "cassandra_asg_desired_size" {}

variable "private_subnet_ids" {
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
