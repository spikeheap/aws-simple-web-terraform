#
#
## Bastion host
data "aws_region" "current" {}

# This module expects tags as a list of maps, so we need to transform the common_tags
# for this
data "null_data_source" "tags" {
  count = "${length(keys(var.common_tags))}"

  inputs = {
    key                 = "${element(keys(var.common_tags), count.index)}"
    value               = "${element(values(var.common_tags), count.index)}"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "bastion_host_sg" {
  vpc_id = "${module.vpc.vpc_id}"
  name = "${var.project_name}-host-sg"

  # Allow HTTP traffic to ALB
  ingress {
    from_port = "${var.docker_compose_http_port}"
    to_port = "${var.docker_compose_http_port}"
    protocol = "tcp"
    cidr_blocks = ["${var.public_subnets}"]
  }

  # Allow HTTPS traffic to ALB
  ingress {
    from_port = "${var.docker_compose_decrypted_https_port}"
    to_port = "${var.docker_compose_decrypted_https_port}"
    protocol = "tcp"
    cidr_blocks = ["${var.public_subnets}"]
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

module "bastion" {
  # source                      = "github.com/terraform-community-modules/tf_aws_bastion_s3_keys"
  source                      = "github.com/spikeheap/tf_aws_bastion_s3_keys?ref=optional_volume_size"

  name                        = "${var.project_name}-bastion-host"
  vpc_id                      = "${module.vpc.vpc_id}"
  instance_type               = "${var.bastion_host_instance_type}"
  instance_volume_size_gb     = "${var.bastion_host_instance_volume_size_gb}"
  ami                         = "${data.aws_ami.ubuntu.id}"
  region                      = "${data.aws_region.current.name}"
  iam_instance_profile        = "${var.project_name}-s3_readonly-allow_associateaddress"
  s3_bucket_name              = "${var.project_name}-bastion-keys"
  vpc_id                      = "${module.vpc.vpc_id}"
  subnet_ids                  = "${module.vpc.public_subnets}"
  keys_update_frequency       = "5,20,35,50 * * * *"
  eip = "${aws_eip.bastion_host.public_ip}"
  extra_tags = ["${data.null_data_source.tags.*.outputs}"]
  security_group_ids = "${aws_security_group.bastion_host_sg.id}"

  # This is needed to set the EIP, see https://github.com/terraform-community-modules/tf_aws_bastion_s3_keys#example
  additional_user_data_script = <<EOF
# Associate the EIP to the host
REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print $4}')
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
aws ec2 associate-address --region $REGION --instance-id $INSTANCE_ID --allocation-id ${aws_eip.bastion_host.id}

${var.bastion_host_user_data_script}
EOF
}

resource "aws_eip" "bastion_host" {
  vpc = true
}

resource "aws_iam_instance_profile" "s3_readonly-allow_associateaddress" {
  name  = "${var.project_name}-s3_readonly-allow_associateaddress"
  role = "${aws_iam_role.s3_readonly-allow_associateaddress.name}"
}

resource "aws_iam_role" "s3_readonly-allow_associateaddress" {
  name = "${var.project_name}-s3_readonly-allow_associateaddress-role"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "s3_readonly-allow_associateaddress_policy" {
  name = "${var.project_name}-s3_readonly-allow_associateaddress-policy"
  role = "${aws_iam_role.s3_readonly-allow_associateaddress.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1425916919000",
            "Effect": "Allow",
            "Action": [
                "ec2:AssociateAddress",
                "s3:List*",
                "s3:Get*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}




resource "aws_s3_bucket" "ssh_public_keys" {
  region = "${data.aws_region.current.name}"
  bucket = "${var.project_name}-bastion-keys"
  acl    = "private"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1425916919000",
            "Effect": "Allow",
            "Principal": {
                "AWS": "${aws_iam_role.s3_readonly-allow_associateaddress.arn}"
            },
            "Action": [
                "s3:List*",
                "s3:Get*"
            ],
             "Resource": "arn:aws:s3:::${var.project_name}-bastion-keys"
        }
    ]
}
EOF
}

resource "aws_s3_bucket_object" "ssh_public_keys" {
  bucket = "${aws_s3_bucket.ssh_public_keys.bucket}"
  key    = "${element(keys(var.bastion_host_ssh_public_keys), count.index)}.pub"

  # Make sure that you put files into correct location and name them accordingly (`public_keys/{keyname}.pub`)
  content = "${element(values(var.bastion_host_ssh_public_keys), count.index)}"
  count   = "${length(var.bastion_host_ssh_public_keys)}"

  depends_on = ["aws_s3_bucket.ssh_public_keys"]
}