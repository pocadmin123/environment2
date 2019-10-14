provider "aws" {
   access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
   region     = "us-west-2"
  profile    = "default"

#  region  = "us-west-2"
 # profile = "default"
}




resource "aws_vpc" "default" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true

  tags = {
    Name = "${var.vpc_name}"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"

  tags = {
    Name = "${var.IGW_name}"
  }
}

resource "aws_subnet" "subnet1-public" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.public_subnet1_cidr}"
  availability_zone = "us-west-2b"

  tags = {
    Name = "${var.public_subnet1_name}"
  }
}



resource "aws_route_table" "terraform-public" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }

  #route {
  #  cidr_block                = "10.0.0.0/16"
  #  vpc_peering_connection_id = "${aws_vpc_peering_connection.connection.id}"
  #}

  tags = {
    Name = "${var.Main_Routing_Table}"
  }
}

resource "aws_route_table_association" "terraform-public" {
  subnet_id      = "${aws_subnet.subnet1-public.id}"
  route_table_id = "${aws_route_table.terraform-public.id}"
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
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

resource "aws_instance" "default" {
  ami                         = "ami-046eb59f650f0d233"
  availability_zone           = "us-west-2b"
  instance_type               = "t2.micro"
  key_name                    = "sai"
  subnet_id                   = "${aws_subnet.subnet1-public.id}"
  vpc_security_group_ids      = ["${aws_security_group.allow_all.id}"]
  associate_public_ip_address = true
  user_data = "${file("/root/route.sh")}"
  tags = {
    Name  = "Server-TF"
    Env   = "Prod"
    Owner = "kranthi"
  }
#  provisioner "file" {
 #   source      = "route.sh"
  #  destination = "/root/route.sh"
 # }
 # provisioner "remote-exec" {
  #  inline = [
   #   "chmod +x /root/route.sh",
    #  "/root/route.sh"
   # ]
 # }



 # provisioner "local-exec" {

#       command = "sudo iptables -A PREROUTING -t nat -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 8080"
#  }

 # provisioner "local-exec" {

#       command = "sudo sh -c "iptables-save > /etc/iptables.rules"\n"
 # }
}
