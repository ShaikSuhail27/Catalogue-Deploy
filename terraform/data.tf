data "aws_ssm_parameter" "vpc_id" {
  name = "/${var.project_name_u}/${var.Environment}/vpc-id"
}

data "aws_ami" "devops_practice" {
  most_recent      = true
  name_regex       = "Centos-8-DevOps-Practice"
  owners           = ["973714476881"]

  filter {
    name   = "name"
    values = ["Centos-8-DevOps-Practice"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ssm_parameter" "private_subnet_id" {
  name = "/${var.project_name_u}/${var.Environment}/Private-Subnet-id"
}

data "aws_ssm_parameter" "catalogue_sg_id" {
  name = "/${var.project_name_u}/${var.Environment}/catalogue_sg_id"
}

# data "aws_ssm_parameter" "app_alb_listener_arn" {
#   name = "/${var.project_name_u}/${var.Environment}/vapp_alb_listener_arn"
# }