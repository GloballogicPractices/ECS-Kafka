/*
-----------------------------------------------------------------
- Setup creds and region via env variables
- For more details: https://www.terraform.io/docs/providers/aws
-----------------------------------------------------------------
Notes:
 - control_cidr changes for different modules
 - Instance class also changes for different modules
 - Default security group is added where traffic is supposed to flow between VPC
 */

/********************************************************************************/


provider "aws" {
  region = "${var.region}"
}


/* Uncomment this if you want to use
S3 - as backend for terraform state file storage
Terraform locking - You need to have a dynamoDb table with primary-key as
lock_table
terraform {
  required_version = ">= 0.9, <= 0.9.6"
  backend "s3" {
  bucket     = "terraform-myapp-remote-state"
  key        = "terraform.tfstate-development-myapp"
  region     = "us-east-1"
  encrypt    = "true"
  lock_table = "terraform-state"
  }
}
*/


module "vpc" {
   source                   = "../../modules/vpc"
   azs                      = "${var.azs}"
   vpc_cidr                 = "${var.vpc_cidr}"
   public_sub_cidr          = "${var.public_sub_cidr}"
   private_sub_cidr         = "${var.private_sub_cidr}"
   enable_dns_hostnames     = true
   vpc_name                 = "${var.vpc_name}-${var.environment}"
   //-- In case we need to change Domain servers
   //dhcp_domain_name_servers = ["${var.domain_servers}"]
   environment              = "${var.environment}"
}

module "glp-private-zone" {
   source            = "../../modules/route53-hosted-zone"
   hosted_zone_name  = "${var.environment}-internal.com"
   vpc_id            = "${module.glp-vpc.vpc_id}"
}

module "bastion" {
   source                = "../../modules/bastion"
   public_sub_cidr       = "${var.public_sub_cidr}"
   vpc-id                = "${module.vpc.vpc_id}"
   pub_sub_id            = "${module.vpc.aws_pub_subnet_id[0]}"
   region                = "${var.region}"
   bastion_instance_type = "${var.bastion_instance_type}"
   keypair_public_key    = "${var.keypair_public_key}"
   aws_key_name          = "${var.aws_key_name}"
   control_cidr          = "${var.control_cidr}"
   ansible_ssh_user      = "${var.ansible_ssh_user}"
   proxy_cidr            = "${var.proxy_cidr}"
   environment           = "${var.environment}"
}


/* Kafka cluster */
module "ecs-kafka-cluster" {
   source                      = "../../modules/ecs-kafka-zk-cluster"
   private_subnet_ids          = "${module.vpc.aws_pri_subnet_id}"
   vpc-id                      = "${module.vpc.vpc_id}"
   region                      = "${var.region}"
   keypair_public_key          = "${var.keypair_public_key}"
   aws_key_name                = "${var.aws_key_name}"
   control_cidr                = "${var.private_sub_control_cidr}"
   kafka_instance_type         = "${var.kafka_instance_type}"
   efs_data_dir                = "${var.efs_kafka_data_dir}"
   efs_fs_id                   = "${module.efs-private-subnet.efs_fs_id}"
   environment                 = "${var.environment}"
   bastion_sg_id               = "${module.bastion.bastion-sg-id}"
   dependency_id               = "${module.efs-private-subnet.dependency_id}"
   kafka_asg_max_size          = "${var.kafka_asg_max_size}"
   kafka_asg_min_size          = "${var.kafka_asg_min_size}"
   kafka_asg_desired_size      = "${var.kafka_asg_desired_size}"
   ami_owner_name              = "${var.ami_owner_name}"
   ami_name_regex              = "${var.ami_name_regex}"
   vpc_cidr                    = "${var.vpc_cidr}"
}

/* EFS for Kafka */
module "efs-private-subnet" {
   source                = "../../modules/efs"
   efs_cluster_name      = "efs_kafka"
   count                 = "${length(var.azs)}"
   subnet_ids            = "${module.vpc.aws_pri_subnet_id_str}"
   environment           = "${var.environment}"
   // We need SGs for all instances where EFS is to be launched
   security_group_id     = [
                             "${module.ecs-kafka-cluster.kafka-cluster-sg-id}"
                           ]
}


module "aws-log-group" {
   source           = "../../modules/cloudwatch-log-groups"
   log_group_name   = "/ecs/${var.environment}-logs"
   environment      = "${var.environment}"
}


module "ansible-ecs-setup" {
   source                        = "../../modules/ansible-ecs"
   env                           = "${var.environment}"
   region                        = "${var.region}"
   # This is only used for Couchbase server
   route53_private_domain        = "${var.environment}-internal.com"
   # These add explicit dependencies
   dependency_id          = [
                                 "${module.ecs-kafka-cluster.dependency_id}"
                            ]
}
