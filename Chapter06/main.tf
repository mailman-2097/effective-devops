provider "aws" {
  region = "us-east-1"
}

variable "my_default_vpcid" {
  type = string
  default = "vpc-a980c0d3"
}

#updated for us-east-1
module "monolith_application" {
  source         = "github.com/giuseppeborgese/effective_devops_with_aws__second_edition//terraform-modules//monolith-playground"
  my_vpc_id      = "${var.my_default_vpcid}"
  my_subnet      = "subnet-8c7446a2"
  my_ami_id      = "ami-0b69ea66ff7391e80"
  my_pem_keyname = "mykey2"
}
output "monolith_url" { value = "${module.monolith_application.url}"}

resource "aws_security_group" "rds" {
  name        = "allow_from_my_vpc"
  description = "Allow from my vpc"
  vpc_id      = "${var.my_default_vpcid}"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
  }
}

module "db" {
  source = "terraform-aws-modules/rds/aws"
  identifier = "demodb"
  engine            = "mysql"
  engine_version    = "5.7.19"
  instance_class    = "db.t2.micro"
  allocated_storage = 5
  name     = "demodb"
  username = "monty"
  password = "some_pass"
  port     = "3306"

  vpc_security_group_ids = ["${aws_security_group.rds.id}"]
  # DB subnet group
  subnet_ids = ["subnet-d056b4ff", "subnet-b541edfe"]
  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"
  # DB parameter group
  family = "mysql5.7"
  # DB option group
  major_engine_version = "5.7"
}
