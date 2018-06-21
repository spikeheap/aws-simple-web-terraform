# AWS Simple Web Host infrastructure

Sets up the AWS infrastructure to host a Docker Compose-based repository.

This Terraform script creates:

- A single EC2 instance, running Docker Compose, and the suite of services defined in a custom repository's Docker Compose file.
- An HTTP/HTTPS load balancer to proxy requests to the EC2 instance.
- A subdomain URL for the new instance within a Route53 domain.
- A valid HTTPS certificate for the generated subdomain.

To support this it creates:

- A new VPC for this project.
- Security groups to restrict access to the resources.
- An Elastic IP for the EC2 instance.

All AWS resources created by this script are tagged with the `common_tags` defined in `development.tfvars`.

## Important

The default setup for this will create resources which aren't included in the free tier. Please review the setup before running it, and ensure the instance sizes match your needs.

## Prerequisites

- A Git repository holding your Docker Compose setup
- An SSH keypair which grants access to the Git repository (i.e. a deploy keypair)

## Getting set up
Ensure you have your AWS credential set as environment variables:

> Tip: add your credentials to `.env` and prime your shell using `source .env`.

```
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
```

Next, [create an S3 bucket](https://s3.console.aws.amazon.com/s3/home) to store our Terraform state centrally.

Next, rename `development.tfvars.sample` to `development.tfvars` and update to match your requirements.

> Tip: search for "TODO" to identify places in the script where you need to set things yourself.

Now you're ready to initialise Terraform:

```bash
terraform init
```

The `key` setting just provides a prefix to the statefile – this can be set to `staging.tfstate` for now.

Now you're all set up and ready to deploy.

## Deploying the infrastructure

The service can be deployed/updated with:

```
terraform apply -var-file=development.tfvars
```
