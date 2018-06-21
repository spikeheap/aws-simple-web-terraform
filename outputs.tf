output "bastion_command" {
  value = "ssh ${module.bastion.ssh_user}@${aws_route53_record.bastion_host_alias.fqdn}"
}

output "web_service_url" {
  value = "https://${aws_route53_record.load_balancer_alias.fqdn}"
}