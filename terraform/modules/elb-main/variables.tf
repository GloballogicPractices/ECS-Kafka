/* Variable declaration for ELB-http */

variable "elb_name" {}
variable "vpc_id" {}
variable "elb_sg_name" {}
// boolean
variable "elb_is_internal" {}
variable "ssl_certificate_id" {}
variable "healthy_threshold" {}
variable "unhealthy_threshold" {}
variable "timeout" {}
variable "elb_health_target" {}
variable "interval" {}
variable "environment" {}
variable "subnets" {
  default = []
}

variable "elb_control_cidr" {}
#variable "main_zone_id" {}
