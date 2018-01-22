/*
  ingress-cluster
  Cluster to run template ECS tasks
*/


/* This is used to generate data about ami to be used */
data "aws_ami" "ecs-ingress" {
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


resource "aws_launch_configuration" "ingress-cluster" {
  image_id                    = "${data.aws_ami.ecs-ingress.id}"
  name_prefix                 = "ingress-cluster-${var.environment}-"
  instance_type               = "${var.ingress_instance_type}"
  associate_public_ip_address = true
  key_name                    = "${var.aws_key_name}"
  security_groups             = ["${aws_security_group.ingress-cluster-sg.id}"]
  user_data                   = "${data.template_file.userdata-ingress-cluster.rendered}"
  iam_instance_profile        = "${aws_iam_instance_profile.ecs_profile_ingress.name}"
  placement_tenancy           = "default"

  root_block_device {
    volume_type           = "standard"
    volume_size           = 12
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


resource "aws_autoscaling_group" "ingress-cluster" {
  vpc_zone_identifier       = ["${var.public_subnet_ids}"]
  load_balancers            = ["${var.load_balancers}"]
  name                      = "ECS-INGRESS-CLUSTER-${var.environment}"
  max_size                  = "${var.kong_asg_max_size}"
  min_size                  = "${var.kong_asg_min_size}"
  health_check_grace_period = 100
  health_check_type         = "EC2"
  desired_capacity          = "${var.kong_asg_desired_size}"
  force_delete              = false
  launch_configuration      = "${aws_launch_configuration.ingress-cluster.name}"

 // Setting this to true would not allow us to delete the ECS clusters
  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "ECS-INGRESS-INSTANCES"
    propagate_at_launch = true
  }

  tag {
      key                 = "Environment"
      value               = "${var.environment}"
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

  depends_on = ["aws_launch_configuration.ingress-cluster"]
}

resource "aws_ecs_cluster" "ingress-cluster" {
  name = "Ingress-Cluster-${var.environment}"

  lifecycle {
    create_before_destroy = true
  }
}

/* We use this to create this as a dependency for other modules */
resource "null_resource" "module_dependency" {
  depends_on = ["aws_autoscaling_group.ingress-cluster"]
}
