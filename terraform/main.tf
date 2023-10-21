module "catalogue_Instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  ami = data.aws_ami.devops_practice.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [data.aws_ssm_parameter.catalogue_sg_id.value]
  subnet_id              =  element ((split(",",data.aws_ssm_parameter.private_subnet_id.value)), 0)
  #user_data = file("mongodb.sh")
   tags = merge(
    var.common_tags_u,
    {
        Name = "${var.project_name_u}-${var.Environment}-catalogue AMI"
    }
    
  )
}
resource "null_resource" "cluster" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    instance_id = module.catalogue_Instance.id
  }

  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
     type = "ssh"
     user = "centos"
     password = "DevOps321"
     host = module.catalogue_Instance.private_ip
  }
# copying the catalogue.sh file to server 
  provisioner "file" {
    source      = "catalogue.sh"
    destination = "/tmp/catalogue.sh"
  }

  provisioner "remote-exec" {
    # Bootstrap script called with private_ip of each node in the cluster
    inline = [
      "chmod +x /tmp/catalogue.sh",
      "sudo sh /tmp/catalogue.sh ${var.app_version}"
    ]
  }
}

# stopping the instance for taking the ami
resource "aws_ec2_instance_state" "catalogue" {
  instance_id = module.catalogue_Instance.id
  state       = "stopped"
}

# need to take ami after stopping the instance
resource "aws_ami_from_instance" "catalogue-Dev-Ami" {
  name               = "${var.common_tags.component}-${local.date}"
  source_instance_id = module.catalogue_Instance.id
}
#aws ec2 terminate-instances --instance-ids i-12345678
resource "null_resource" "catalogue-delete" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    ami_id= aws_ami_from_instance.catalogue-Dev-Ami.id
  }

  provisioner "local-exec" {
    # Bootstrap script called with private_ip of each node in the cluster
    command  = [
      "aws ec2 terminate-instances --instance-ids ${module.catalogue_Instance.id}"
    ]
  }
}

#catalogue target group
resource "aws_lb_target_group" "catalogue" {
  name     = "${var.project_name_u}-${var.common_tags_u.Component}-${var.Environment}"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_ssm_parameter.vpc_id.value
  deregistration_delay = 60
  health_check {
    enabled = true
    healthy_threshold = 2 # it will check the health whether it is good or not
    interval = 15
    matcher = "200-299"
    path = "/health"
    port = 8080
    protocol = "HTTP"
    timeout = 5
    unhealthy_threshold = 3
  }
  }
# launch template creation
resource "aws_launch_template" "Catalogue" {
  name = "${var.project_name_u}-${var.common_tags_u.Component}-${var.Environment}"
  # here we need to provide our configured AMI so no need of user data as well
  image_id = aws_ami_from_instance.catalogue-Dev-Ami.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type = "t2.micro"
  vpc_security_group_ids = [data.aws_ssm_parameter.catalogue_sg_id.value]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "Catalogue"
    }
  }

  //user_data = filebase64("${path.module}/catalogue.sh")
}

#auto_scaling group creation
resource "aws_autoscaling_group" "Catalogue" {
  name                      = "${var.project_name_u}-${var.common_tags_u.Component}-${var.Environment}-${local.date}"
  max_size                  = 5
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 2
  target_group_arns = [aws_lb_target_group.catalogue.arn]
  launch_template {
    id      = aws_launch_template.Catalogue.id
    version = "$Latest"
  }
  vpc_zone_identifier       = split(",",data.aws_ssm_parameter.private_subnet_id.value)

  tag {
    key                 = "Name"
    value               = "Catalogue"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }

  timeouts {
    delete = "15m"
  }
}
#Autoscaling policy
resource "aws_autoscaling_policy" "catalogue" {
  # ... other configuration ...
  autoscaling_group_name = aws_autoscaling_group.Catalogue.name
  name                   = "cpu"
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 50.0
  }
}

#listener rule
resource "aws_lb_listener_rule" "static" {
  listener_arn = data.aws_ssm_parameter.app_alb_listener_arn.value
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.catalogue.arn
  }

  # condition {
  #   path_pattern {
  #     values = ["/static/*"]
  #   }
  # }

  condition {
    host_header {
      values = ["catalogue.app-DEV.suhaildevops.online"]
    }
  }
}


output "app_version"{
  value = var.app_version
}