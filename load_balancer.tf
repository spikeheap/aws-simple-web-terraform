resource "aws_security_group" "front_end_load_balancer_http_sg" {
  vpc_id = "${module.vpc.vpc_id}"
  name = "${var.project_name}-lb-http-sg"

  # Allow HTTP traffic to ALB
  ingress {
    from_port = "80"
    to_port = "80"
    protocol = "tcp"
    cidr_blocks = ["${var.lb_allowed_cidr_blocks}"]
  }

  # Allow all outbound traffic
  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${var.common_tags}"
}

resource "aws_security_group" "front_end_load_balancer_https_sg" {
  vpc_id = "${module.vpc.vpc_id}"
  name = "${var.project_name}-lb-https-sg"

  # Allow HTTP traffic to ALB
  ingress {
    from_port = "443"
    to_port = "443"
    protocol = "tcp"
    cidr_blocks = ["${var.lb_allowed_cidr_blocks}"]
  }

  # Allow all outbound traffic
  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${var.common_tags}"
}

resource "aws_lb" "front_end_load_balancer" {
  name            = "${var.project_name}-load-balancer"
  internal        = false
  security_groups = ["${aws_security_group.front_end_load_balancer_http_sg.id}",
                     "${aws_security_group.front_end_load_balancer_https_sg.id}"]
  subnets         = ["${module.vpc.public_subnets}"]

  tags = "${var.common_tags}"
}

resource "aws_lb_target_group" "front_end_https" {
  name     = "${var.project_name}-https-tg"
  port     = "${var.docker_compose_decrypted_https_port}"
  protocol = "HTTP"
  vpc_id   = "${module.vpc.vpc_id}"

  health_check {
    matcher = "${var.load_balancer_https_healthcheck_code}"
  }
  
  tags = "${var.common_tags}"
}

resource "aws_autoscaling_attachment" "bastion_https_tg" {
  alb_target_group_arn   = "${aws_lb_target_group.front_end_https.arn}"
  autoscaling_group_name = "${module.bastion.asg_id}"
}

resource "aws_lb_listener" "front_end_https" {
  load_balancer_arn = "${aws_lb.front_end_load_balancer.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  certificate_arn   = "${aws_acm_certificate_validation.cert.certificate_arn}"

  default_action {
    target_group_arn = "${aws_lb_target_group.front_end_https.arn}"
    type             = "forward"
  }
}

resource "aws_lb_target_group" "front_end_http" {
  name     = "${var.project_name}-http-tg"
  port     = "${var.docker_compose_http_port}"
  protocol = "HTTP"
  vpc_id   = "${module.vpc.vpc_id}"

  health_check {
    matcher = "${var.load_balancer_http_healthcheck_code}"
  }
  
  tags = "${var.common_tags}"
}

resource "aws_autoscaling_attachment" "bastion_http_tg" {
  alb_target_group_arn   = "${aws_lb_target_group.front_end_http.arn}"
  autoscaling_group_name = "${module.bastion.asg_id}"
}

resource "aws_lb_listener" "front_end_http" {
  load_balancer_arn = "${aws_lb.front_end_load_balancer.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.front_end_http.arn}"
    type             = "forward"
  }
}