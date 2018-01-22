// Bastion-node-sg
resource "aws_security_group" "jump-sg" {
   name   = "jump-sg"
   vpc_id = "${var.vpc-id}"

   ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["${split(",",var.control_cidr)}"]
   }

   egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
   }
}
