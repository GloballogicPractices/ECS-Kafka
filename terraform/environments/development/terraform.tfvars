/*
 Variables for deploying stack
--------------------------------
- ACM certificates have to pre-exist
*/

// General
region            = "eu-central-1" #Select a region based on your preference
vpc_name          = "Custom-VPC"
vpc_cidr          = "10.2.0.0/16"
// This is for generated ssh.cfg if you want to get into the instance
proxy_cidr        = "10.2.*"

/*
Environment keyword is important
- This will become suffix for your clusters
- Ansible roles for deployments are called based on the environment
- For simplicity we keep this as development.
*/

environment       = "development"

# AZs are combintation of az length + subnet cidrs
public_sub_cidr   = ["10.2.0.0/24","10.2.1.0/24","10.2.2.0/24"]
private_sub_cidr  = ["10.2.3.0/24","10.2.4.0/24","10.2.5.0/24"]
azs               = ["eu-central-1a","eu-central-1b","eu-central-1c"]


// You can reduce the size if you do not want to incur cost
bastion_instance_type        = "t2.micro"
ingress_instance_type        = "t2.medium"
cassandra_instance_type      = "t2.medium"
kafka_instance_type          = "t2.medium"

# Ansible auto ssh - used when you want to do host level
# configuration
ansible_ssh_user  = "ec2-user"
ansible_user      = "ansible"


// For public facing sites and ELBs
// Applications will be accessible from these IPs only
control_cidr = "52.45.0.0/16,138.5.0.0/16"

// ASG Size
cassandra_asg_max_size = 3
cassandra_asg_min_size = 3
cassandra_asg_desired_size = 3
# ECS KONG cluster
kong_asg_max_size = 3
kong_asg_min_size = 3
kong_asg_desired_size = 3
# ECS Kafka cluster
kafka_asg_max_size = 3
kafka_asg_min_size = 3
kafka_asg_desired_size = 3

// Route53 - required
// main_zone_id       = "*********" # If you plan to use the route53
// public_domain_name = "Mydomain.com"


// Same as vpc cidr. Can change upon vpc peering
private_sub_control_cidr ="10.2.0.0/16"


// AMIs to be used based on owner name and ami name regex
// Using Weave-ECS AMI
// ami_owner_name   = OwnerId

ami_owner_name   = "MUST_SPECIFY"
ami_name_regex   = "Weaveworks*ECS*Image*"


// Cassandra EBS
cass_ebs_dev_name  = "/dev/xvdf"
# This needs to be io1 for prod
cass_ebs_vol_type  = "gp2"
cass_ebs_vol_size  = 50
cass_data_dir      = "/cassandra-data"

// Kafka EFS
efs_kafka_data_dir  = "/kafka-data"


// Kong-external-elb
kong_elb_name                = "kong-external"
kong_elb_sg_name             = "kong-external-elb-sg"
kong_elb_healthy_threshold   = 10
kong_elb_unhealthy_threshold = 2
kong_elb_timeout             = 10
kong_elb_elb_health_target   = "HTTP:8001/"
kong_elb_interval            = "15"
// Certificate must be available in IAM or ACM and must match region being deployed in
kong_ssl_certificate_id      = "ARNOFYOURCERT"

// Main-elb
main_elb_name                = "main-elb"
main_elb_sg_name             = "main-elb-sg"
main_elb_healthy_threshold   = 10
main_elb_unhealthy_threshold = 2
main_elb_timeout             = 10
main_elb_elb_health_target   = "HTTP:8001/"
main_elb_interval            = "15"
// Certificate must be available in IAM or ACM and must match region being deployed in
main_ssl_certificate_id      = "ARNOFYOURCERT"
