/*
   Variables for all modules
*/

// VPC
variable "region" {}
variable "vpc_cidr" {}
variable "aws_key_path" {}
variable "aws_key_name" {}
variable "keypair_public_key" {}
variable "vpc_name" {}
variable "environment" {}
variable "private_sub_control_cidr" {}
variable "ansible_ssh_user" {}
variable "control_cidr" {}
variable "proxy_cidr" {}
variable "ami_owner_name" {}
variable "ami_name_regex" {}

// Route53
variable "main_zone_id" {}
variable "public_domain_name" {}


// ELB Kong
variable "kong_elb_name" {}
variable "kong_elb_sg_name" {}
variable "kong_elb_healthy_threshold" {}
variable "kong_elb_unhealthy_threshold" {}
variable "kong_elb_timeout" {}
variable "kong_elb_elb_health_target" {}
variable "kong_elb_interval" {}
variable "kong_ssl_certificate_id" {}

// ELB Main
variable "main_elb_name" {}
variable "main_elb_sg_name" {}
variable "main_elb_healthy_threshold" {}
variable "main_elb_unhealthy_threshold" {}
variable "main_elb_timeout" {}
variable "main_elb_elb_health_target" {}
variable "main_elb_interval" {}
variable "main_ssl_certificate_id" {}


// Cassandra EBS
variable "cass_ebs_dev_name" {}
variable "cass_ebs_vol_type" {}
variable "cass_ebs_vol_size" {}
variable "cass_data_dir" {}


// Declare classes of instances for each modules
variable "bastion_instance_type" {}
variable "ingress_instance_type" {}
variable "cassandra_instance_type" {}


// ASG size for each cluster

variable "cassandra_asg_max_size" {}
variable "cassandra_asg_min_size" {}
variable "cassandra_asg_desired_size" {}
variable "kong_asg_max_size" {}
variable "kong_asg_min_size" {}
variable "kong_asg_desired_size" {}


// Generic
variable "azs" {
    default = []
}


variable "public_sub_cidr" {
     default = []
}


variable "private_sub_cidr" {
     default = []
}
