terraform {
  backend "s3" {
    region = "eu-west-2"
  }
}

provider "aws" {
  region = "eu-west-2" # EU (Ireland)
}

variable "project_name" {
  description = "The project name, to prefix resources. Dash-case, e.g. my-sample-project"
}

variable "common_tags" {
  type ="map"
  description = "Tags to apply to all AWS resources"
  default = {
    Terraform = "true"
  }
}

#
# VPC configuration
#

variable "vpc_cidr" {
  description = "The CIDR to use for the VPC."
  default = "10.0.0.0/16"
}

variable "availability_zones" {
  type = "list"
  description = "The list of availability zones to use for the VPC. This must match your provider region."
  default = [
      "eu-west-2a",
      "eu-west-2b", 
      "eu-west-2c"
    ]
}



variable "public_subnets"  {
  type = "list"
  description = "The list of public subnets to use for the VPC."
  default = [
      "10.0.101.0/24", 
      "10.0.102.0/24", 
      "10.0.103.0/24"
    ]
}

#
# Bastion host
#
variable "bastion_host_instance_type" {
  description = "The AWS EC2 instance type for the bastion host"
  default = "t2.nano"
}

variable "bastion_host_ssh_public_keys" {
  description = "The map of public keys for users of the bastion host"
  default = {}
}

variable "bastion_host_user_data_script" {
  description = "Additional script to be run on resource creation"
  default = ""
}

variable "bastion_host_instance_volume_size_gb" {
  description = "The root volume size, in gigabytes"
  default = "8"
}

#
# Docker-compose host
#
variable "docker_compose_http_port" {
  description = "The port to forward HTTP traffic to from the load balancer"
}

variable "docker_compose_decrypted_https_port" {
  description = "The port to forward decrypted HTTPS traffic to from the load balancer. May be the same as docker_compose_http_port"
}

#
# Load balancer
#
variable load_balancer_fqdn {
  description = "The FQDN of the load balancer, e.g. 'www.example.com'. Must be a subdomain of the Route53 zone"
}

variable lb_allowed_cidr_blocks {
  description = "The CIDR blocks allowed to connect to the load balancer"
  default = ["0.0.0.0/0"]
}

variable load_balancer_http_healthcheck_code {
  description = "The HTTP status code expected from a healthy HTTP target in the load balancer"
  default = "200" 
}

variable load_balancer_https_healthcheck_code {
  description = "The HTTP status code expected from a healthy HTTPS target in the load balancer"
  default = "200" 
}

#
# Shared configuration
#
variable "route53_zone_name" {
  description = "The Route53 zone, .e.g 'example.com.' (the trailing '.' is important)"
}

variable "route53_cname_ttl" {
  description = "The TTL for Route53 DNS records"
  default = "300"
}

variable "docker_compose_instance_type" {
  description = "The AWS EC2 instance type for the docker-compose host"
  default = "t2.medium"
}