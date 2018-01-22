/*
  kafka-clusters without ECS
*/


/* This is used to generate data about ami to be used */
data "aws_ami" "kafka" {
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


resource "aws_launch_configuration" "kafka-cluster-lc" {
  image_id                    = "${data.aws_ami.kafka.id}"
  name_prefix                 = "kafka-cluster-${var.environment}-"
  instance_type               = "${var.kafka_instance_type}"
  associate_public_ip_address = true
  key_name                    = "${var.aws_key_name}"
  security_groups             = ["${aws_security_group.kafka-cluster-sg.id}"]
  user_data                   = "${data.template_file.userdata-kafka-cluster.rendered}"
  iam_instance_profile        = "${aws_iam_instance_profile.ecs-profile-kafka.name}"
  placement_tenancy           = "default"

  root_block_device {
    volume_type           = "standard"
    volume_size           = 30
    delete_on_termination = true
  }

  connection {
    user  = "ec2-user"
    agent = true
  }

  lifecycle {
    create_before_destroy = true
  }

}


resource "aws_autoscaling_group" "kafka-cluster-asg" {
  vpc_zone_identifier       = ["${var.private_subnet_ids}"]
  name                      = "ECS-KAFKA-CLUSTER-${var.environment}"
  max_size                  = "${var.kafka_asg_max_size}"
  min_size                  = "${var.kafka_asg_min_size}"
  health_check_grace_period = 100
  health_check_type         = "EC2"
  desired_capacity          = "${var.kafka_asg_desired_size}"
  force_delete              = false
  launch_configuration      = "${aws_launch_configuration.kafka-cluster-lc.name}"

 // Setting this to true would not allow us to delete the ECS clusters
  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "ECS-KAFKA-INSTANCES-${upper(var.environment)}"
    propagate_at_launch = true
  }

  tag {
      key                 = "Environment"
      value               = "${var.environment}"
      propagate_at_launch = true
  }

  // This will decide Ansible role to be applied via dynamic inventory
  tag {
    key                 = "Role1"
    value               = "kafka_instances"
    propagate_at_launch = true
  }

  tag {
    key                 = "Role2"
    value               = "zookeeper_instances"
    propagate_at_launch = true
  }

  tag{
    key                 = "Stack"
    value               = "GLP"
    propagate_at_launch = true
  }

  tag{
    key                 = "weave:peerGroupName"
    value               = "GLP-${var.environment}"
    propagate_at_launch = true
  }

  depends_on = ["aws_launch_configuration.kafka-cluster-lc"]
}

resource "aws_ecs_cluster" "kafka-cluster" {
  name = "Kafka-cluster-${var.environment}"

  lifecycle {
    create_before_destroy = true
  }
}

/* We use this to create this as a dependency for other modules */
resource "null_resource" "module_dependency" {
  depends_on = ["aws_autoscaling_group.kafka-cluster-asg"]
}
