### HA Kafka cluster on ECS
---  


###### -- Three node kafka cluster which includes HA zookeeper
###### -- EFS volumes mounted and used by both Kafka & Zookeeper
###### -- Scalable - Easy horizontal scaling for Kafka nodes

<br />

#### Weave with ECS
---

![alt text](https://raw.githubusercontent.com/GloballogicPractices/ECS-kafka/master/images/kafka-on-ecs.png)

<br />



##### This repository
- Terraform modules and code to deploy a highly available Kong cluster in ECS
- Ansible Integration to demonstrate concepts for deploying Kong and Cassandra services
- A python utility that manages deployement on ECS rather than relying on Ansible's ECS module.
  -  Lack of ability to deploy a service across multiple cluster led to a custom utility
- Also demonstrate deploy and destroy time provisioners in Terraform
- Demostrate use of WeaveWorks networking in deploying the cluster and service discovery in ECS
- Demonstrate use of overlay network for ECS
- Demonstrate use of Cloudwatch-logs. A log group and stream is setup for log forwarding and aws logging driver is used.
- Demonstrate cloud-init with Terraform




##### Pre-requisites
- AWS account. Obviously!
- Terraform > 0.9.5
- Ansible >= 2.3
- Python 2.7
- Boto, Botocore
- Registerred Domain and Route53 Hosted zone ( Good to have else you have to change code )
- Related ACM certificates for your domain ( Good to have else you have to change code )

<br />

#### Deployment architecture
---
![alt text](https://raw.githubusercontent.com/faizan82/ECS-kong/master/images/kong-architecture.png)


<br />

### Deployment
---
#### What is deployed?
1. VPC - Three private subnets and three public subnets
2. Two ECS Clusters ( Kong and Cassandra in public and private subnets respectively)
3. A bastion node.
4. AWS Log group and log stream
5. EBS Volumes of 50G attached to each Cassandra node using cloud-init
6. Route53 entries based on choosen domain names and details provided to Terraform


#### Deployment procedure
1. Ensure pre-requisites are met
2. Decide a region where this needs to be deployed
3. This guides a cluster in a region with 3 AZs. You can reduce the number in terraform.tfvars file
4. Generate your ACM Certificates for the domain
5. Ensure a private key is available in AWS


```shell
# Prepare your environment ( Terraform and Ansible )
# Change directory to terraform/environments/development
# We are considering a sample development environment
# Update secrets.tf file with your public key

$ cat secrets.tf
aws_key_name = "test-cluster-key"
aws_key_path = "~/.ssh/test-cluster-key.pem"
// Can be generated using
// ssh-keygen -y -f mykey.pem > mykey.pub
keypair_public_key = "ssh-rsa publickey" # Replace this with public key corresponding to your private key in AWS

# You can use any authentication procedures mentioned here https://www.terraform.io/docs/providers/aws/

$ export AWS_ACCESS_KEY_ID="anaccesskey"
$ export AWS_SECRET_ACCESS_KEY="asecretkey"
$ export AWS_DEFAULT_REGION="us-west-2"

```

#### terraform.tfvars for your infra

```shell
/*
 Variables for deploying stack
--------------------------------
- ACM certificates have to pre-exist
*/

// General
region            = "eu-central-1" #Select a region based on your preference
vpc_name          = "kong-VPC"
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


// Route53 - required
// main_zone_id       = "*********" # If you plan to use the route53
// public_domain_name = "Mydomain.com"


// Same as vpc cidr. Can change upon vpc peering
private_sub_control_cidr ="10.2.0.0/16"


// AMIs to be used based on owner name and ami name regex
// Using Weave-ECS AMI
// ami_owner_name   = OwnerId

ami_owner_name   = "376248598259"
ami_name_regex   = "Weaveworks*ECS*Image*"


// Cassandra EBS
cass_ebs_dev_name  = "/dev/xvdf"
# This needs to be io1 for prod
cass_ebs_vol_type  = "gp2"
cass_ebs_vol_size  = 50
cass_data_dir      = "/cassandra-data"


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
```


##### Plan and setup
```shell
terraform plan -var-file="secrets.tf"
# If successful then
terraform apply -varf-file="secrets.tf"
## There should be no manual intervention required.
```


##### Note
- Cost: This is beyond the scope of Free-tier since we use two ELBs and t2.medium instances. You can reduce t2.medium to micro and replace ELBs with your own loadbalancers but you will have to update the code
- Kong-limitation: A single node needs to be deployed first and then can be scaled due to limitation with https://github.com/Mashape/kong/issues/2139
- Cassandra: There is no concept of master - slave. However, for clustering it expects a pre-existing Seed Node. In order to achieve this, a Seed Node is deployed and then clients are added. Based on the choosen replication factor, there can be data replicated across all nodes
- Environment: The environment keyword is used to pickup a defined ansible role. If you change or add new environments, ensure that corresponding Yaml file exists in Ansible role

For information on Ecs utility : https://github.com/faizan82/ecs-orchestrate
