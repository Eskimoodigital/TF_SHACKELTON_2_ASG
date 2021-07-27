
#Simple Terraform code to build an ASG with 2 web servers




#============================PROVIDERS============================================================




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

#============================GET SUBNET IDs FOR THE ASG============================================================

data "aws_vpc" "default" {
    default = true
  
}


data "aws_subnet_ids" "default" {
    vpc_id = data.aws_vpc.default.id
  
}
#============================ASG CONFIG============================================================



resource "aws_launch_configuration" "eskimoo16661" {
    image_id = "ami-00f22f6155d6d92c5"
    instance_type = "t2.micro"
    security_groups = [aws_security_group.instance.id]
    key_name = "KP_ESK_EC2_INST1"
    

    user_data = <<-EOF
                #!/bin/bash
                sudo yum install -y httpd
                sudo systemctl start httpd
                EOF
    lifecycle {
      create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "eskimoo16661"{
    launch_configuration = aws_launch_configuration.eskimoo16661
    target_group_arns = [aws_lb_target_group.asg.arn]
    min_size = 2
    max_size = 4
    vpc_zone_identifier = data.aws_subnet_ids.default.ids

    tag {
        key = "Name"
        value = "Eskimoo-ASG-example"
        propagate_at_launch = true
    }
}

#============================SG REFERENCE FOR ASG MEMBERS============================================================

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




#============================LOAD BALANCER============================================================

resource "aws_lb" "eskimooLB" {
    name = "eskimoo_LB_example"
    load_balancer_type = "application"
    subnets = data.aws_subnet_ids.default.ids
    security_groups = [aws.aws_security_group.alb.id]
  
}



resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.eskimooLB.arn
    port = 80
    protocol = "HTTP"

    default_action {
      type = "fixed-response"

      fixed_response {
        content_type = "text/plain"
        message_body = "404: page not found"
        status_code = 404
      }
    }
  
}


resource "aws_lb_listener_rule" "asg" {
    listener_arn = aws_lb_listener.http.arn
    priority = 100

    condition {
      path_pattern {
          values =["*"]
      }
    }

    action {
      type = "forward"
      target_group_arn = aws_lb_target_group.asg.arn
    }
  
}

resource "aws_lb_target_group" "asg" {
    name = "terraform-asg-example"
    port = 80
    protocol = "HTTP"
    vpc_id = data.aws_vpc.default.id

    health_check {
      path = "/"
      protocol = "HTTP"
      matcher = "200"
      interval = 15
      timeout = 3
      healthy_threshold = 2
      unhealthy_threshold = 2
    
  
}

#============================SG REFERENCE FOR LB============================================================

#define AWS resources

resource "aws_security_group" "alb" {
    name = "terraform-example-alb"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    }

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }
} 
#============================OUTPUTS============================================================


#get the public dns so we can test the web server

output "publicdns" {
    value = aws_instance.eskimoo16661.public_dns
}
