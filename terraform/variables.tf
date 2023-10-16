variable "project_name_u"{
    default = "Roboshop"
}

variable "common_tags_u" {
    default = {
        Name = "Roboshop"
        Component = "Catalogue"
        Environment = "DEV"
        Terraform = true
    }
}

variable "Environment"{
    default="DEV"
}
variable "app_version" {
  default = "100.1"
}