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


output "app_version"{
  value = var.app_version
}