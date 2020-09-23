########################################################################
############################################################ INSTANCES #
########################################################################


resource "aws_instance" "inst_ngn1" {
  ami           = "ami-0701e7be9b2a77600"
  instance_type = "t2.nano"
  key_name        = var.key_name
  subnet_id     = aws_subnet.yakir_subnet1.id
  vpc_security_group_ids = [aws_security_group.yakir_priv_sg1.id]

  connection {
    host        = coalesce(self.public_ip, self.private_ip)
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_path)
  }
  user_data = data.template_file.user_data_pub_key.rendered

  tags = {
    "name" = "inst_ngn1",
    "type" = "nginx",
    "project" = var.project,
  }
  

}


resource "aws_instance" "inst_ngn2" {
  ami           = "ami-0701e7be9b2a77600"
  instance_type = "t2.nano"
  key_name        = var.key_name
  subnet_id     = aws_subnet.yakir_subnet2.id
  vpc_security_group_ids = [aws_security_group.yakir_priv_sg1.id]


  connection {
    host        = coalesce(self.public_ip, self.private_ip)
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_path)
  }
  user_data = data.template_file.user_data_pub_key.rendered

  tags = {
    "Name" = "inst_ngn2",
    "type" = "nginx",
    "project" = "earn_ha"
  }
}

resource "aws_instance" "inst_app1" {
  ami           = "ami-0701e7be9b2a77600"
  instance_type = "t2.nano"
  key_name        = var.key_name
  subnet_id     = aws_subnet.yakir_subnet1.id
  vpc_security_group_ids = [aws_security_group.yakir_priv_sg1.id]

  connection {
    host        = coalesce(self.public_ip, self.private_ip)
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_path)
  }
  user_data = data.template_file.user_data_pub_key.rendered


  tags = {
    "Name" = "inst_app1",
    "type" = "app"
    "project" = "earn_ha"
  }
}


resource "aws_instance" "inst_app2" {
  ami           = "ami-0701e7be9b2a77600"
  instance_type = "t2.nano"
  key_name        = var.key_name
  subnet_id     = aws_subnet.yakir_subnet2.id
  vpc_security_group_ids = [aws_security_group.yakir_priv_sg1.id]

  connection {
    host        = coalesce(self.public_ip, self.private_ip)
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_path)
  }
  user_data = data.template_file.user_data_pub_key.rendered


  tags = {
    "Name" = "inst_app2",
    "type" = "app",
    "project" = "earn_ha"
  }
}



## 1 way to configure an host file
resource "null_resource" "config_ansible_hosts_file" {


  provisioner "local-exec" {
    command = "echo '${data.template_file.env_hosts.rendered}' > earn_hosts"
  }


}



/*
## run ansible playbooks with my configured ansible hosts file
resource "null_resource" "setup_env_old" {


  provisioner "local-exec" {
    command = "ansible-playbook -i var.cust_ans_hosts_file  var.setup_docker_play_file"
    command = "ansible-playbook -i var.cust_ans_hosts_file  var.deploy_nginx_play_file"
    command = "ansible-playbook -i var.cust_ans_hosts_file  var.deploy_app_play_file"
  }


}*/


## run ansible playbooks with dynamic hosts (using aws_c2 plugin)
resource "null_resource" "setup_env" {

  depends_on = [
    aws_instance.inst_app1,
    aws_instance.inst_app2,
    aws_instance.inst_ngn1,
    aws_instance.inst_ngn2,
    aws_lb.front_end
  ]

  provisioner "local-exec" {

    
    command = "ansible-playbook  -e $passed_in_hosts -e  $ansible_python_interpreter  $setup_docker_play_file"


    environment = {
      passed_in_hosts = "passed_in_hosts=tag_project_earn_ha"
      ansible_python_interpreter = "ansible_python_interpreter=python3"
      setup_docker_play_file = "./ansible/setup_docker.yml"
      
    }
  }

  provisioner "local-exec" {

    command = "ansible-playbook  -e $passed_in_hosts -e  $ansible_python_interpreter $deploy_app_play_file"

    environment = {
      passed_in_hosts = "passed_in_hosts=tag_type_app"
      ansible_python_interpreter = "ansible_python_interpreter=python3"
      deploy_app_play_file = "./ansible/deploy_simple-web.yml"
    }
  }

  provisioner "local-exec" {

    command = "ansible-playbook  -e $passed_in_hosts -e  $ansible_python_interpreter $deploy_nginx_play_file"

      environment = {
      passed_in_hosts = "passed_in_hosts=tag_type_nginx"
      ansible_python_interpreter = "ansible_python_interpreter=python3"
      deploy_nginx_play_file = "./ansible/deploy_nginx.yml"
    }


  }




}



##################################################################################
# VARIABLES
##################################################################################

#variable "aws_access_key" {}
#variable "aws_secret_key" {}
#variable "private_key_path" {}



variable "key_name" {
  default = "yh_terf"
}



variable "network_address_space" {
  default = "10.2.0.0/16"
}
variable "subnet1_address_space" {
  default = "10.2.1.0/24"
}

variable "subnet2_address_space" {
  default = "10.2.2.0/24"
}

variable "project" {
  default = "earn_ha"
}



variable "cust_ans_hosts_file" {
  default = "./earn_hosts"
}


variable "setup_docker_play_file" {
  default = "./ansible/setup_docker.yml "
}

variable "deploy_nginx_play_file" {
  default = "./ansible/deploy_nginx.yml"
}

variable "deploy_app_play_file" {
  default = "./ansible/deploy_simple-web.yml"
}







##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {

  #0.12.14 Interpolation-only expressions are deprecated: an expression like "${foo}" should be rewritten as just foo.
  #access_key = var.aws_access_key
  #secret_key = var.aws_secret_key
  #region     = "eu-west-1"
  version = "~> 2.63"
}



##################################################################################
# DATA 
##################################################################################




data "template_file" "user_data_priv_key" {
  template = file("templates/user_data_priv_key.tpl")

}


data "template_file" "user_data_pub_key" {
  template = file("templates/user_data_pub_key.tpl")
}

data "template_file" "env_hosts" {
  template = file("templates/env_hosts.tpl")
  /*depends_on = [
    "aws_instance.dev-api-gateway",
    "aws_instance.dev-api-gateway-internal"
  ]*/
  vars  = {
    server_nginx_1 = aws_instance.inst_ngn1.public_ip
    server_nginx_2 = aws_instance.inst_ngn2.public_ip
    server_app_1 = aws_instance.inst_app1.public_ip
    server_app_2 = aws_instance.inst_app2.public_ip
  }
}



data "aws_availability_zones" "available" {}



##################################################################################
# OUTPUT
##################################################################################



output "inst_ngn1_ip" {
  value = aws_instance.inst_ngn1.public_ip
}

output "inst_ngn2_ip" {
  value = aws_instance.inst_ngn2.public_ip
}

output "inst_app1_ip" {
  value = aws_instance.inst_app1.public_ip
}

output "inst_app2_ip" {
  value = aws_instance.inst_app2.public_ip
}










##################################################################################
###################################################################### RESOURCES##
##################################################################################


###########################################################
############################################# NETWORKING ##
###########################################################
resource "aws_vpc" "yakir_vpc1" {
  cidr_block = var.network_address_space
  enable_dns_hostnames = "true"
  tags = {
        "Name" = "yakir_vpc1"
    }

}

resource "aws_internet_gateway" "yakir_igw1" {
  vpc_id = aws_vpc.yakir_vpc1.id
    tags = {
        "Name" = "yakir_igw1"
    }

}


resource "aws_subnet" "yakir_subnet1" {
  cidr_block        = var.subnet1_address_space
  vpc_id            = aws_vpc.yakir_vpc1.id
  map_public_ip_on_launch = "true"
  availability_zone = data.aws_availability_zones.available.names[0]
   tags = {
        "Name" = "yakir_subnet1"
    }

}


resource "aws_subnet" "yakir_subnet2" {
  cidr_block        = var.subnet2_address_space
  vpc_id            = aws_vpc.yakir_vpc1.id
  map_public_ip_on_launch = "true"
  availability_zone = data.aws_availability_zones.available.names[1]
  #availability_zone = "${data.aws_availability_zones.available.names[0]}"
  #availability_zone = "${data.aws_ebs_volume.jen_serv_ebs_volume.availability_zone}"
     tags = {
        "Name" = "yakir_subnet2"
    }

}




############################################################ ROUTING #

## route table
resource "aws_route_table" "yakir_rt1" {
  vpc_id = aws_vpc.yakir_vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.yakir_igw1.id
  }
     tags = {
        "Name" = "yakir_rt1"
    }
}

resource "aws_route_table_association" "yakir_rta_subnet1" {
  subnet_id      = aws_subnet.yakir_subnet1.id
  route_table_id = aws_route_table.yakir_rt1.id
}



resource "aws_route_table_association" "yakir_rta_subnet2" {
  subnet_id      = aws_subnet.yakir_subnet2.id
  route_table_id = aws_route_table.yakir_rt1.id
}






#################################################################################
############################################################ SECURITY GROUPS ####
##################################################################################






# public security group 
resource "aws_security_group" "yakir_pub_sg1" {
  name        = "yakir_pub_sg1"
  vpc_id      = aws_vpc.yakir_vpc1.id

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

     tags = {
        "Name" = "yakir_pub_sg1"
    }

}

# alb security group 
resource "aws_security_group" "yakir_alb_sg1" {
  name        = "yakir_alb_sg1"
  vpc_id      = aws_vpc.yakir_vpc1.id

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

     tags = {
        "Name" = "yakir_alb_sg1"
    }

}


resource "aws_security_group" "yakir_priv_sg1" {
  name        = "yakir_priv_sg"
  vpc_id      = aws_vpc.yakir_vpc1.id

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # http access for nginx servers
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

   # http access for app servers
  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }



  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
     tags = {
        "Name" = "yakir_priv_sg1"
    }

}




##############################################################
#                                                            #
#         ALB application load balancer                      #
#                                                            #
##############################################################

### alb load balancer
resource "aws_lb" "front_end" {
  name               = "yakir-alb1"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.yakir_alb_sg1.id]
  subnets            = [aws_subnet.yakir_subnet1.id,aws_subnet.yakir_subnet2.id]

  enable_deletion_protection = false



  tags = {
    Name = "yakir_alb1"
  }
}

## alb listener
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.front_end.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content"
      status_code  = "200"
    }
  }
}

##alb target group
resource "aws_lb_target_group" "front_end_ngn" {
  name     = "yakir-lb-tg1"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.yakir_vpc1.id
}

##alb target group
resource "aws_lb_target_group" "front_end_app" {
  name     = "yakir-lb-tg2"
  port     = 8081
  protocol = "HTTP"
  vpc_id   = aws_vpc.yakir_vpc1.id
}


##alb target group attachment
resource "aws_lb_target_group_attachment" "ngn1" {
  target_group_arn = aws_lb_target_group.front_end_ngn.arn
  target_id        = aws_instance.inst_ngn1.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "ngn2" {
  target_group_arn = aws_lb_target_group.front_end_ngn.arn
  target_id        = aws_instance.inst_ngn2.id
  port             = 8080
}

##alb target group attachment
resource "aws_lb_target_group_attachment" "apps1" {
  target_group_arn = aws_lb_target_group.front_end_app.arn
  target_id        = aws_instance.inst_app1.id
  port             = 8081
}

resource "aws_lb_target_group_attachment" "apps2" {
  target_group_arn = aws_lb_target_group.front_end_app.arn
  target_id        = aws_instance.inst_app2.id
  port             = 8081
}



resource "aws_lb_listener_rule" "host_based_routing_ngn" {
  listener_arn = aws_lb_listener.front_end.arn
  #priority     = 99

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_end_ngn.arn
  }

  condition {
    host_header {
      values = ["mynginx.com"]
    }
  }
}


resource "aws_lb_listener_rule" "host_based_routing_app" {
  listener_arn = aws_lb_listener.front_end.arn
  #priority     = 99

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_end_app.arn
  }

  condition {
    host_header {
      values = ["myapp.com"]
    }
  }
}


