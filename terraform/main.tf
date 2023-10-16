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

output "app_version"{
  value = var.app_version
}