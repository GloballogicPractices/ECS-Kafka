/* Specify all templates to be used here */

data "template_file" "ssh_cfg" {
     template   = "${file("${path.module}/templates/ssh.cfg")}"
     depends_on = [ ]

     vars {
       jump_public_ip    = "${aws_eip.jump-node.public_ip}"
       jump_public_dns   = "${aws_instance.jump_node.public_dns}"
       ansible_ssh_user  = "${var.ansible_ssh_user}"
       proxy_cidr        = "${var.proxy_cidr}"
     }

}



data "template_file" "userdata-bastion" {
   template = "${file("${path.module}/templates/userdata_bastion")}"
}
