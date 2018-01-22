/* We use this to track dependecies between each modules */


output "dependency_id" {
  value = "${null_resource.module_dependency.id}"
}

output "zone-id" {
  value = "${aws_route53_zone.private-zone.id}"
}
