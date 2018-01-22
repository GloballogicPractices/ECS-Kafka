/* We use this to track dependencies between each modules */
output "dependency_id" {
  value = "${null_resource.module_dependency.id}"
}

output "main-elb-name" {
   value = "${aws_elb.main-external-elb.name}"
}

output "main-elb-zone-id" {
   value = "${aws_elb.main-external-elb.zone_id}"
}

output "main-elb-dns-name" {
   value = "${aws_elb.main-external-elb.dns_name}"
}
