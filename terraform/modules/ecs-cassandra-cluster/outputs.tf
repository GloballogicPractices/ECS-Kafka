/* We use this to track dependecies between each modules */
output "dependency_id" {
  value = "${null_resource.module_dependency.id}"
}

output "cassandra-cluster-sg-id" {
   value = "${aws_security_group.cassandra-cluster-sg.id}"
}

// This is used in userdata
output "cassandra_cluster_name" {
   value = "${aws_ecs_cluster.cassandra-cluster.name}"
}
