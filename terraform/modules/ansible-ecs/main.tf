/*
This module will generate config for our ansible playbooks
We need to pass env, region and cluster name for all applications to
our ansible roles.
Two provisioners to be used
- create time ( deploy all services )
- destroy time ( delete all ecs cluster else tf wont be able to destroy completely )
*/


data "template_file" "ansible_ecs_deploy" {
     template   = "${file("${path.module}/templates/ansible_ecs_deploy.sh")}"

     vars {
       env                          = "${lower(var.env)}"
       region                       = "${var.region}"
       log_group_name               = "${var.log_group_name}"
     }

}

data "template_file" "ansible_ecs_destroy" {
     template   = "${file("${path.module}/templates/ansible_ecs_destroy.sh")}"

     vars {
       env                          = "${lower(var.env)}"
       region                       = "${var.region}"
       log_group_name               = "${var.log_group_name}"
     }

}


resource "null_resource" "ansible_ecs_generate" {

   triggers {
      # This will trigger create on every run
      filename = "test-${uuid()}"
   }

   provisioner "local-exec" {
      command = "echo '${ data.template_file.ansible_ecs_deploy.rendered }' > ../../../ansible/ansible_call_deploy.sh"
   }

   provisioner "local-exec" {
      command = "chmod 755 ../../../ansible/ansible_call_deploy.sh"
   }

   provisioner "local-exec" {
      command = "../../../ansible/ansible_call_deploy.sh"
   }

}



resource "null_resource" "ansible_ecs_destroy" {

   triggers {
      template_rendered = "${data.template_file.ansible_ecs_destroy.rendered}"
   }

   provisioner "local-exec" {
      command = "echo '${ data.template_file.ansible_ecs_destroy.rendered }' > ../../../ansible/ansible_call_destroy.sh"
      when    = "destroy"
   }

   provisioner "local-exec" {
      command = "chmod 755 ../../../ansible/ansible_call_destroy.sh"
      when    = "destroy"
   }

   provisioner "local-exec" {
      command = "../../../ansible/ansible_call_destroy.sh"
      when    = "destroy"
   }

}
