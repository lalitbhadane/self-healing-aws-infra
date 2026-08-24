resource "aws_secutrity_group" "instance" {
  name		= "instance-security-group"
  description   = "Allow HTTP only from ALB, all outbound"
  vpc_id 	= var.vpc_id

  ingress {
    description	     = "HTTP from ALB only"
    from_port	     = 80
    to_port          = 80
    protocol	     = "tcp"
    security_groups  = [var.alb_security_group_id]
  }
  egress {
    description      = "Allow all outbound"
    from_port        = 0
    to_port	     = 0
    protocol	     = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "instance-security-group"
  }
}
