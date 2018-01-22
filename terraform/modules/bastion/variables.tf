/*
   Variables for bastion
*/

variable "keypair_public_key" {}
variable "vpc-id" {}
variable "region" {}
variable "pub_sub_id" {}
variable "aws_key_name" {}
variable "ansible_ssh_user" {}
variable "proxy_cidr" {}
variable "bastion_instance_type" {}
variable "environment" {}



variable "dependency_id" {
  default = ""
}

variable "public_sub_cidr" {
     default = []
}

variable "control_cidr" {
}
