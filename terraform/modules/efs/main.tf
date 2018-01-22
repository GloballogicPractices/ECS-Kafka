/* EFS Module for connecting EFS to EC2 instances */

resource "aws_efs_file_system" "efs" {
  creation_token = "${var.efs_cluster_name}-efs"
  tags {
    Name = "${var.efs_cluster_name}-efs"
    Terraform = "true"
    Environment = "${var.environment}"
    Stack       = "GLP"
  }
}

// stuck here
resource "aws_efs_mount_target" "efs" {
  file_system_id = "${aws_efs_file_system.efs.id}"
  count = "${var.count}"
  subnet_id = "${element(split(",",var.subnet_ids),count.index)}"
  security_groups = [ "${var.security_group_id}" ]

  depends_on = ["aws_efs_file_system.efs"]
}


/* We use this to create this as a dependency for other modules */
resource "null_resource" "module_dependency" {
  depends_on = ["aws_efs_mount_target.efs"]
}
