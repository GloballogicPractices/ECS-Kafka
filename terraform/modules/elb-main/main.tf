/**********************************************
 ELB - Module
 - Create ELBs
 - Use the output to use ELBs in ASGs
**********************************************/

# External load balancer for Kong transformation
resource "aws_elb" "main-external-elb" {
  name               = "${var.elb_name}"
  internal           = "${var.elb_is_internal}"
  security_groups    = ["${aws_security_group.main-elb.id}"]
  subnets            = ["${var.subnets}"]

  listener {
    instance_port      = 8000
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "${var.ssl_certificate_id}"
  }

  health_check {
    healthy_threshold   = "${var.healthy_threshold}"
    unhealthy_threshold = "${var.unhealthy_threshold}"
    timeout             = "${var.timeout}"
    target              = "${var.elb_health_target}"
    interval            = "${var.interval}"
  }

  tags {
    Name        = "${var.elb_name}"
    environment = "${var.environment}"
  }
}


/* We use this to create this as a dependency for other modules */
resource "null_resource" "module_dependency" {
  depends_on = ["aws_elb.main-external-elb"]
}
