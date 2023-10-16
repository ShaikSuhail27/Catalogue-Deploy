#! /bin/bash
APP_VERSION=$1
echo "app version is $APP_VERSION"
yum install python3.11-devel python3.11-pip -y
 pip3.11 install ansible botocore boto3
 cd /tmp
 ansible-pull -U https://github.com/ShaikSuhail27/Ansible-Roboshop-Roles-TF.git -e app_version=$APP_VERSION -e component=catalogue main.yaml



#  ### vARIABLES FLOW:
#  1.Through CI we will receive the version to deploy
#  2.we need to pass that version to the terraform
#  3.we need to pass that version to the shell script for execution
#  4.we need to receive that version in sh file
#  5.we need to declare that variable in ansible configuration and pass it in sh file
