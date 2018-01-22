/* Register ELB with route53 dns service
examples
- main_zone_id: Z2WUFSTRXBZ83 (public hosted zone)
- main_dns_name: kong-stage.mydomain.com
- elb_main_name: module.elb.dns_name
- elb_zone_id: module.elb.zone_id
*/

resource "aws_route53_record" "external-elb" {
  # Create this resource if needed
  zone_id = "${var.main_zone_id}"
  name    = "${var.main_dns_name}.${var.route53_domain}"
  type    = "A"

  alias {
    name                   = "${var.elb_main_name}"
    zone_id                = "${var.elb_main_zone_id}"
    evaluate_target_health = true
  }
}
