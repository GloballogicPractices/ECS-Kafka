/*
   Variables for ECS_CLUSTER
*/


variable "keypair_public_key" {}
variable "vpc-id" {}
variable "region" {}
variable "aws_key_name" {}
variable "environment" {}
variable "kafka_instance_type" {}
variable "control_cidr" {}
variable "efs_data_dir" {}
variable "efs_fs_id" {}
variable "bastion_sg_id" {}
#variable "vpc_sg_id" {}
variable "ami_owner_name" {}
variable "ami_name_regex" {}
variable "vpc_cidr" {}

// ASG
variable "kafka_asg_max_size" {}
variable "kafka_asg_min_size" {}
variable "kafka_asg_desired_size" {}


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
