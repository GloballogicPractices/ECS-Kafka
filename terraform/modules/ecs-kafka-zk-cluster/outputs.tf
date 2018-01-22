/* We use this to track dependecies between each modules */
output "dependency_id" {
  value = "${null_resource.module_dependency.id}"
}

output "kafka-cluster-sg-id" {
   value = "${aws_security_group.kafka-cluster-sg.id}"
}

// This is used in userdata
output "kafka_cluster_name" {
   value = "${aws_ecs_cluster.kafka-cluster.name}"
}
