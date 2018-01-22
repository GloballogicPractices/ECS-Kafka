/* private hosted zone */

resource "aws_route53_zone" "private-zone" {
  name   = "${var.hosted_zone_name}"
  vpc_id = "${var.vpc_id}"
}


resource "null_resource" "module_dependency" {
   depends_on = [
        "aws_route53_zone.private-zone",
   ]
}
