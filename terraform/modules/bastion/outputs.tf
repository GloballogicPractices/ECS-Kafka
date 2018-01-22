output "bastion-sg-id" {
   value = "${aws_security_group.jump-sg.id}"
}

output "ip_authorised_for_inbound_traffic" {
   value = "${var.control_cidr}"
}


output "bastion_eip" {
   value = "${aws_eip.jump-node.public_ip}"
}

output "bastion_dns" {
   value = "${aws_instance.jump_node.public_dns}"
}
