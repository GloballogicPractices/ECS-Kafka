### HA Kafka cluster on ECS
---  


###### -- Three node kafka cluster which includes HA zookeeper
###### -- EFS volumes mounted and used by both Kafka & Zookeeper
###### -- Scalable - Easy horizontal scaling for Kafka nodes

<br />

![alt text](https://github.com/GloballogicPractices/ECS-Kafka/blob/master/images/kafka.png)

<br />
=======




##### This repository
- Terraform modules and code to deploy a highly available Ka cluster in ECS
- Ansible Integration to demonstrate concepts for deploying Kafka and Cassandra services
- A python utility that manages deployement on ECS rather than relying on Ansible's ECS module.
  -  Lack of ability to deploy a service across multiple cluster led to a custom utility
- Also demonstrate deploy and destroy time provisioners in Terraform
- Orchestration of ECS tasks using ansible where statefulsets are not available. 
- Demonstrate use of Cloudwatch-logs. A log group and stream is setup for log forwarding and aws logging driver is used.
- Demonstrate cloud-init with Terraform
- Deployment of EFS for Kafka/Zookeeper




##### Pre-requisites
- AWS account.
- Terraform > 0.9.5
- Ansible >= 2.3
- Python 2.7
- Boto, Botocore

<br />

#### Deployment architecture
---
![alt text](https://github.com/GloballogicPractices/ECS-Kafka/blob/master/images/kafka-on-ecs.png)


<br />

NOTE: Kong can be deployed as a proxy server using code from https://github.com/GloballogicPractices/ECS-Kong


### Deployment
---
#### What is deployed?
1. VPC - Three private subnets and three public subnets
2. One ECS Cluster ( Kafka private subnets respectively)
3. A bastion node.
4. AWS Log group and log stream
5. EBS Volumes of 50G attached to each Cassandra node using cloud-init
6. Route53 for private hosted zone
7. EFS as backing storage

#### Deployment procedure
1. Ensure pre-requisites are met
2. Decide a region where this needs to be deployed
3. This guides a cluster in a region with 3 AZs. You can reduce the number in terraform.tfvars file
4. Ensure a private key is available in AWS


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
kafka_instance_type          = "t2.medium"

# Ansible auto ssh - used when you want to do host level
# configuration
ansible_ssh_user  = "ec2-user"
ansible_user      = "ansible"


// For public facing sites and ELBs
// Applications will be accessible from these IPs only
control_cidr = "52.45.0.0/16,138.5.0.0/16"

# ECS Kafka cluster
kafka_asg_max_size = 3
kafka_asg_min_size = 3
kafka_asg_desired_size = 3


// Same as vpc cidr. Can change upon vpc peering
private_sub_control_cidr ="10.2.0.0/16"



// Kafka EFS
// Zookeeper config is stored in a sub directorty
// under kafka directory
efs_kafka_data_dir  = "/kafka-data"

```


##### Plan and setup
```shell
terraform plan -var-file="secrets.tf"
# If successful then
terraform apply -varf-file="secrets.tf"
## There should be no manual intervention required.
```


##### Note
- Cost: This is beyond the scope of Free-tier.
- Environment: The environment keyword is used to pickup a defined ansible role. If you change or add new environments, ensure that corresponding Yaml file exists in Ansible role
- Private hosted zone takes the form of 
```shell
kafka.{{environment}-internal.com
```
For information on Ecs utility : https://github.com/faizan82/ecs-orchestrate
