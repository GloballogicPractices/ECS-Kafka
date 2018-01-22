/*
 Variables for EFS
*/

variable "efs_cluster_name" {}
variable "subnet_ids" {}
variable "environment" {}
variable "count" {}
variable "security_group_id" {
   default = []
}
