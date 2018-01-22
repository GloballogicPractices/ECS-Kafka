/* We use this to track dependencies between each modules */
output "dependency_id" {
  value = "${null_resource.module_dependency.id}"
}

// This is used in userdata
output "ecs_cluster_name" {
   value = "${aws_ecs_cluster.ingress-cluster.name}"
}


output "ingress-cluster-sg" {
   value = "${aws_security_group.ingress-cluster-sg.id}"
}
