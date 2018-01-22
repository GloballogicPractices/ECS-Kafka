/*
  Bastion-node
  Nothing else apart from sshd to be on this node
*/

/* This is used to generate data about ami to be used */
data "aws_ami" "bastion" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs*"]
  }

}


resource "aws_instance" "jump_node" {
    ami                         = "${"${data.aws_ami.bastion.id}"}"
    instance_type               = "${var.bastion_instance_type}"
    key_name                    = "${var.aws_key_name}"
    vpc_security_group_ids      = ["${aws_security_group.jump-sg.id}"]
    #count                      = "${length(var.public_sub_cidr)}"
    user_data                   = "${data.template_file.userdata-bastion.rendered}"
    subnet_id                   = "${var.pub_sub_id}"
    associate_public_ip_address = true
    source_dest_check           = false
    // Implicit dependency
    iam_instance_profile        = "${aws_iam_instance_profile.bastion_profile.name}"

    tags = {
      Name        = "ECS-BASTION-NODE-${var.environment}"
      Role        = "bastion"
      Environment = "${var.environment}"
    }

}


//assgin eip to jump-node
resource "aws_eip" "jump-node" {
    instance = "${aws_instance.jump_node.id}"
    vpc      = true
}
