# task-api-infra — Terraform infrastructure on AWS

Project 3 of the DevOps portfolio series. Provisions the AWS infrastructure
that runs the `task-api` container published by the Project 2 CI/CD pipeline
(`ghcr.io/claudfeh/task-api:latest`).

## What gets created

```
                 ┌─────────────────────────────────────────┐
                 │ VPC 10.0.0.0/16                         │
                 │                                         │
Internet ──8080─►│ public subnet 10.0.1.0/24               │
                 │  ┌──────────────────────────────────┐   │
                 │  │ EC2 (t3.micro, Amazon Linux 2023)│   │
                 │  │  ┌──────┐  ┌─────┐  ┌────────┐    │   │
                 │  │  │proxy │─►│ app │─►│   db   │    │   │
                 │  │  │nginx │  │Flask│  │postgres│    │   │
                 │  │  └──────┘  └─────┘  └────────┘    │   │
                 │  └──────────────────────────────────┘   │
                 │                                         │
                 └─────────────────────────────────────────┘
```

- **VPC** with DNS support, one **public subnet**, **internet gateway**,
  and a **route table** sending `0.0.0.0/0` to the gateway
- **Security group**: port 8080 open to the world (the app), port 22 for
  SSH (tighten `ssh_allowed_cidrs` to your IP)
- **EC2 instance** (`t3.micro`, free-tier eligible) whose `user_data`
  installs Docker + Compose and boots the full stack — the same three
  services as the local Compose file, but the app image is pulled from
  GHCR instead of built locally
- **Remote state**: the `.tfstate` file lives in an S3 bucket, not on
  your laptop

## Prerequisites

1. An AWS account (free tier) with an access key — see "AWS credentials"
   below. The instance type is free-tier eligible, but **destroy the
   infrastructure when you're done** (`terraform destroy`) or the meter
   keeps running.
2. An S3 bucket for remote state. Create it once in the AWS console
   (S3 → Create bucket, globally unique name, defaults are fine, turning
   on versioning is recommended). Then put the bucket name in `main.tf`
   where it says `CHANGE_ME-task-api-tfstate`.
3. The GHCR package `claudfeh/task-api` must be **public** (GitHub
   profile → Packages → task-api → Package settings → Change visibility),
   otherwise the EC2 instance can't pull the image without credentials.

## AWS credentials

Install AWS CLI v2, then run `aws configure` and paste the access key ID,
secret access key, region (`us-east-1`), and output format (`json`).
Create the access key at AWS console → IAM → Users → your user →
Security credentials → Create access key.

## Usage

```bash
terraform init     # downloads the AWS provider, connects the S3 backend
terraform plan     # shows what will be created — read it before applying
terraform apply    # type "yes" — creates the VPC, instance, everything

# after ~2-3 minutes (Docker install + image pulls on first boot):
curl http://<app_url_from_outputs>/api/tasks

terraform destroy  # type "yes" — tears it ALL down. Do this when done.
```

## What this demonstrates

- **VPC networking from scratch** — subnets, IGW, route tables, security
  groups; the database-equivalent tier is unreachable from the internet
- **Immutable compute bootstrap** — `user_data` installs Docker and
  launches the exact CI-published image; no snowflake servers
- **Remote state in S3** — state survives laptop loss and enables locking
- **Data sources** — the AMI is looked up dynamically (`al2023-ami-*`),
  never hardcoded
- **Variables + outputs** — region, instance type, and image owner are
  inputs; the app URL is an output
- **Cost awareness** — free-tier instance type, and teardown is part of
  the documented workflow

## Series roadmap

1. ✅ `task-api` — containerized app
2. ✅ CI/CD pipeline with GitHub Actions (build → test → push to GHCR)
3. ✅ `task-api-infra` — Terraform on AWS (this repo)
4. ⬜ Kubernetes manifests + Helm chart
