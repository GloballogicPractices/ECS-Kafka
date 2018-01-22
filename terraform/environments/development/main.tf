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


module "ecs-cassandra-cluster" {
   source                      = "../../modules/ecs-cassandra-cluster"
   private_subnet_ids          = "${module.vpc.aws_pri_subnet_id}"
   vpc-id                      = "${module.vpc.vpc_id}"
   region                      = "${var.region}"
   keypair_public_key          = "${var.keypair_public_key}"
   aws_key_name                = "${var.aws_key_name}"
   control_cidr                = "${var.private_sub_control_cidr}"
   cassandra_instance_type     = "${var.cassandra_instance_type}"
   #vpc_sg_id                  = "${module.vpc.aws_default_sg_id}"
   environment                 = "${var.environment}"
   bastion_sg_id               = "${module.bastion.bastion-sg-id}"
   //dependency_id             = "${module.efs-private-subnet.dependency_id}"
   cass_ebs_dev_name           = "${var.cass_ebs_dev_name}"
   cass_ebs_vol_type           = "${var.cass_ebs_vol_type}"
   cass_ebs_vol_size           = "${var.cass_ebs_vol_size}"
   cass_data_dir               = "${var.cass_data_dir}"
   cassandra_asg_max_size      = "${var.cassandra_asg_max_size}"
   cassandra_asg_min_size      = "${var.cassandra_asg_min_size}"
   cassandra_asg_desired_size  = "${var.cassandra_asg_desired_size}"
   ami_owner_name              = "${var.ami_owner_name}"
   ami_name_regex              = "${var.ami_name_regex}"
   vpc_cidr                    = "${var.vpc_cidr}"
}


module "ecs-ingress-cluster" {
   source                       = "../../modules/ecs-kong-cluster"
   vpc-id                       = "${module.vpc.vpc_id}"
   public_subnet_ids            = "${module.vpc.aws_pub_subnet_id}"
   region                       = "${var.region}"
   load_balancers               = [ "${module.kong-external-elb.kong-external-elb-name}",
                                    "${module.external-elb.main-elb-name}"
                                  ]
   keypair_public_key           = "${var.keypair_public_key}"
   aws_key_name                 = "${var.aws_key_name}"
   control_cidr                 = "${var.private_sub_control_cidr}"
   bastion_sg_id                = "${module.bastion.bastion-sg-id}"
   environment                  = "${var.environment}"
   ingress_instance_type        = "${var.ingress_instance_type}"
   kong_asg_max_size            = "${var.kong_asg_max_size}"
   kong_asg_min_size            = "${var.kong_asg_min_size}"
   kong_asg_desired_size        = "${var.kong_asg_desired_size}"
   ami_owner_name               = "${var.ami_owner_name}"
   ami_name_regex               = "${var.ami_name_regex}"
   vpc_cidr                     = "${var.vpc_cidr}"
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


/**********************************
This requires
- ACM certificates for the domains
***********************************/
module "kong-external-elb" {
   source              = "../../modules/elb-kong"
   vpc_id              = "${module.vpc.vpc_id}"
   subnets             = "${module.vpc.aws_pub_subnet_id}"
   elb_is_internal     = "false"
   elb_name            = "${var.kong_elb_name}"
   elb_control_cidr    = "${var.control_cidr}"
   elb_sg_name         = "${var.kong_elb_sg_name}"
   healthy_threshold   = "${var.kong_elb_healthy_threshold}"
   unhealthy_threshold = "${var.kong_elb_unhealthy_threshold}"
   timeout             = "${var.kong_elb_timeout}"
   elb_health_target   = "${var.kong_elb_elb_health_target}"
   interval            = "${var.kong_elb_interval}"
   ssl_certificate_id  = "${var.kong_ssl_certificate_id}"
   environment         = "${var.environment}"
}


# Main ELB for transformation via kong
module "external-elb" {
   source              = "../../modules/elb-main"
   vpc_id              = "${module.vpc.vpc_id}"
   subnets             = "${module.vpc.aws_pub_subnet_id}"
   elb_is_internal     = "false"
   elb_name            = "${var.main_elb_name}-${var.environment}"
   elb_control_cidr    = "${var.control_cidr}"
   elb_sg_name         = "${var.main_elb_sg_name}"
   healthy_threshold   = "${var.main_elb_healthy_threshold}"
   unhealthy_threshold = "${var.main_elb_unhealthy_threshold}"
   timeout             = "${var.main_elb_timeout}"
   elb_health_target   = "${var.main_elb_elb_health_target}"
   interval            = "${var.main_elb_interval}"
   ssl_certificate_id  = "${var.main_ssl_certificate_id}"
   environment         = "${var.environment}"
}


/*
- Creating alias records to KONG node. All of this routing will be done via API-GW
- Requires Pre-existing domain name
- You can disable the below modules if you do not have a domain registerred
*/

module "main-dns-entry" {
   source           = "../../modules/route53-elb"
   main_zone_id     = "${var.main_zone_id}"
   main_dns_name    = "myapp-${var.environment}"
   route53_domain   = "${var.public_domain_name}"
   elb_main_name    = "${module.external-elb.main-elb-dns-name}"
   elb_main_zone_id = "${module.external-elb.main-elb-zone-id}"
}

module "kong-dns-entry" {
   source           = "../../modules/route53-elb"
   main_zone_id     = "${var.main_zone_id}"
   main_dns_name    = "kong-${var.environment}"
   route53_domain   = "${var.public_domain_name}"
   elb_main_name    = "${module.kong-external-elb.kong-external-elb-dns-name}"
   elb_main_zone_id = "${module.kong-external-elb.kong-external-elb-zone-id}"
}

module "aws-log-group" {
   source           = "../../modules/cloudwatch-log-groups"
   log_group_name   = "/ecs/${var.environment}-logs"
   environment      = "${var.environment}"
}


# Local provisioning
module "ansible-ecs-setup" {
   source                        = "../../modules/ansible-ecs"
   env                           = "${var.environment}"
   region                        = "${var.region}"
   log_group_name                = "/ecs/${var.environment}-logs"
   # These add explicit dependencies
   dependency_id          = [
                                 "${module.ecs-cassandra-cluster.dependency_id}",
                                 "${module.ecs-ingress-cluster.dependency_id}",
                                 "${module.vpc.vpc_id}"
                            ]
}
