/* Specify all templates to be used here */

data "template_file" "userdata-ingress-cluster" {
   template = "${file("${path.module}/templates/userdata-ingress-cluster")}"

   vars {
     ecs_cluster_name = "${aws_ecs_cluster.ingress-cluster.name}"
   }
}
