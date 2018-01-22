/* Specify all templates to be used here */

data "template_file" "userdata-kafka-cluster" {
   template = "${file("${path.module}/templates/userdata-kafka-cluster")}"

   vars {
     ecs_cluster_name    = "${aws_ecs_cluster.kafka-cluster.name}"
     efs_data_dir        = "${var.efs_data_dir}"
     efs_fs_id           = "${var.efs_fs_id}"
     region              = "${var.region}"
   }
}
