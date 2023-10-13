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
        Name = "${var.project_name_u}-${var.Environment}-catalogue"
    }
    
  )
}