output "efs_fs_id" {
  value = "${aws_efs_file_system.efs.id}"
}

/*
output "sub_id" {
  value = "${aws_efs_mount_target.efs.subnet_id}"
}
*/

output "dependency_id" {
  value = "${null_resource.module_dependency.id}"
}
