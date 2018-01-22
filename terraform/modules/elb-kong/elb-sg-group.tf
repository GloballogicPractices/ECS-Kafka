/* Security Group Resource for Module ELB */


// SG for kong elb
resource "aws_security_group" "kong-elb" {
    name = "${var.elb_sg_name}"
    description = "Security Group ELB ${var.elb_sg_name}"
    vpc_id = "${var.vpc_id}"

    // allow traffic for TCP 443
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["${split(",",var.elb_control_cidr)}"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
