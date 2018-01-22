/*
  Cassandra-clusters
*/


/* This is used to generate data about ami to be used */
data "aws_ami" "cassandra-ecs" {
  most_recent = true

  filter {
    name = "owner-id"
    values = ["${var.ami_owner_name}"]
  }

  filter {
    name = "name"
    values = ["${var.ami_name_regex}"]
  }

}


// Cassandra currently does not work with EFS
// We have to attach EBS volumes for now
resource "aws_launch_configuration" "cassandra-cluster-lc" {
  image_id                    = "${data.aws_ami.cassandra-ecs.id}"
  name_prefix                 = "cassandra-cluster-${var.environment}-"
  instance_type               = "${var.cassandra_instance_type}"
  associate_public_ip_address = true
  key_name                    = "${var.aws_key_name}"
  security_groups             = ["${aws_security_group.cassandra-cluster-sg.id}"]
  user_data                   = "${data.template_file.userdata-cassandra-cluster.rendered}"
  iam_instance_profile        = "${aws_iam_instance_profile.ecs_profile-cassandra.name}"
  // This will change for production
  placement_tenancy           = "default"

  root_block_device {
    volume_type           = "standard"
    volume_size           = 50
    delete_on_termination = false
  }

  ebs_block_device {
    device_name           = "${var.cass_ebs_dev_name}"
    volume_type           = "${var.cass_ebs_vol_type}"
    volume_size           = "${var.cass_ebs_vol_size}"
    // This has to persist post reboots
    delete_on_termination = false
  }

  connection {
    user  = "ec2-user"
    agent = true
  }

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_autoscaling_group" "cassandra-cluster-asg" {
  vpc_zone_identifier       = ["${var.private_subnet_ids}"]
  name                      = "ECS-CASSANDRA-CLUSTER-${var.environment}"
  max_size                  = "${var.cassandra_asg_max_size}"
  min_size                  = "${var.cassandra_asg_min_size}"
  health_check_grace_period = 100
  health_check_type         = "EC2"
  desired_capacity          = "${var.cassandra_asg_desired_size}"
  force_delete              = false
  launch_configuration      = "${aws_launch_configuration.cassandra-cluster-lc.name}"

 // Setting this to true would not allow us to delete the ECS clusters
  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "ECS-CASSANDRA-INSTANCES"
    propagate_at_launch = true
  }

  tag {
      key                 = "Environment"
      value               = "${var.environment}"
      propagate_at_launch = true
  }

  // This will decide Ansible role to be applied via dynamic inventory
  tag {
    key                 = "Role"
    value               = "cassandra-instances"
    propagate_at_launch = true
  }

  tag{
    key                 = "Stack"
    value               = "MyStack"
    propagate_at_launch = true
  }

  tag{
    key                 = "weave:peerGroupName"
    value               = "MyStack-${var.environment}"
    propagate_at_launch = true
  }


  depends_on = ["aws_launch_configuration.cassandra-cluster-lc"]
}

resource "aws_ecs_cluster" "cassandra-cluster" {
  name = "Cassandra-Cluster-${var.environment}"

  lifecycle {
    create_before_destroy = true
  }
}

/* We use this to create this as a dependency for other modules */
resource "null_resource" "module_dependency" {
  depends_on = ["aws_autoscaling_group.cassandra-cluster-asg"]
}
