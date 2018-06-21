data "aws_route53_zone" "zone" {
  name = "${var.route53_zone_name}"
  private_zone = false
}

resource "aws_route53_record" "bastion_host_alias" {
  zone_id = "${data.aws_route53_zone.zone.id}"
  name    = "${var.project_name}-bh"
  type    = "A"
  ttl     = "${var.route53_cname_ttl}"
  records = [ "${aws_eip.bastion_host.public_ip}" ]
}

resource "aws_route53_record" "load_balancer_alias" {
  zone_id = "${data.aws_route53_zone.zone.id}"
  name    = "${var.load_balancer_fqdn}"
  type    = "A"

  alias {
    name                   = "${aws_lb.front_end_load_balancer.dns_name}"
    zone_id                = "${aws_lb.front_end_load_balancer.zone_id}"
    evaluate_target_health = false
  }
}

#
# Certificate validation
#


resource "aws_acm_certificate" "cert" {
  domain_name = "${var.load_balancer_fqdn}"
  validation_method = "DNS"
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn = "${aws_acm_certificate.cert.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation.fqdn}"]
}
resource "aws_route53_record" "cert_validation" {
  name = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_name}"
  type = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.aws_route53_zone.zone.id}"
  records = ["${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"]
  ttl = 60
}