/* We use this to track dependencies between each modules */
output "dependency_id" {
  value = "${null_resource.module_dependency.id}"
}

output "kong-external-elb-name" {
   value = "${aws_elb.kong-external-elb.name}"
}


output "kong-external-elb-zone-id" {
   value = "${aws_elb.kong-external-elb.zone_id}"
}

output "kong-external-elb-dns-name" {
   value = "${aws_elb.kong-external-elb.dns_name}"
}
