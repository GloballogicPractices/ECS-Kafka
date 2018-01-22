/* Specify all templates to be used here */

data "template_file" "userdata-cassandra-cluster" {
   template = "${file("${path.module}/templates/userdata-cassandra-cluster")}"

   vars {
     ecs_cluster_name = "${aws_ecs_cluster.cassandra-cluster.name}"
     //region         = "${var.region}"
     device_id        = "${var.cass_ebs_dev_name}"
     cass_data_dir    = "${var.cass_data_dir}"

   }
}
