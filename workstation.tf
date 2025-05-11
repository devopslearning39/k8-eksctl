module "ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "workstation"
  # ami = data.aws_ami.centos8.id
  ami           = "ami-0b4f379183e5706b9"
  instance_type = "t2.micro"
  #   key_name               = "user1"
  #   monitoring             = true
  vpc_security_group_ids = [aws_security_group.allow_eksctl.id]
  subnet_id              = "subnet-058a7562114623eda"
  user_data              = file("workstation.sh")
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_security_group" "allow_eksctl" {
  name        = "allow_eksctl"
  description = "Craeted for eksctl"
  tags = {
    Name = "allow_eksctl"
  }

  ingress {
    description = "all ports"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# data "aws_ami" "centos8" {
#   most_recent      = true
#   owners           = ["692859912310"]

#   filter {
#     name   = "name"
#     values = ["Centos-8-DevOps-Practice"]
#   }

#   filter {
#     name   = "root-device-type"
#     values = ["ebs"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
# }
