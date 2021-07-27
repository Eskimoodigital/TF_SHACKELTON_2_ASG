

#define the terraform providers

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}


#define the AWS region

provider "aws" {
    region = "eu-central-1"
}




resource "aws_instance" "eskimoo16661" {
    ami = "ami-00f22f6155d6d92c5"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.instance.id]
    key_name = "KP_ESK_EC2_INST1"

    user_data = <<-EOF
                #!/bin/bash
                sudo yum install -y httpd
                sudo systemctl start httpd
                EOF
  
    tags = {
        Name = "eskimooexample"
    }

}


#define AWS resources

resource "aws_security_group" "instance" {
    name = "terraform-example-instance"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }
} 

#get the public dns so we can test the web server

output "publicdns" {
    value = aws_instance.eskimoo16661.public_dns
}
