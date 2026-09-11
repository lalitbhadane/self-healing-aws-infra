# Self-Healing Multi-Tier AWS Infrastructure

A production-style AWS infrastructure project built with **Terraform**, designed to demonstrate infrastructure as code, secure networking, monitoring, self-healing architecture, and GitHub Actions CI/CD.

> **Project status:** Core AWS infrastructure, monitoring, GitHub Actions CI, GitHub OIDC authentication, and remote Terraform state are implemented. Full CI/CD deployment, the self-healing failure demonstration, final architecture documentation, and the PostgreSQL authentication test are still in progress.

---

## Project Goal

The goal is to build a secure, highly available, and self-healing multi-tier application infrastructure on AWS while following real-world DevOps practices.

The project demonstrates:

- Infrastructure as Code with Terraform
- Multi-tier AWS networking
- High availability across multiple Availability Zones
- Application Load Balancing
- Auto Scaling and instance health replacement
- Private application and database tiers
- CloudWatch monitoring and SNS alerting
- Secure GitHub Actions → AWS authentication using OIDC
- Remote Terraform state stored in S3
- Terraform state locking
- CI/CD automation
- Cost-conscious AWS usage and cleanup

---

## Architecture

```text
                         Internet
                            │
                            │ HTTP :80
                            ▼
                  ┌───────────────────┐
                  │        ALB        │
                  │ Application LB    │
                  └─────────┬─────────┘
                            │
                 ┌──────────┴──────────┐
                 │                     │
                 ▼                     ▼
          ┌─────────────┐       ┌─────────────┐
          │ EC2 / ASG   │       │ EC2 / ASG   │
          │ Private AZ1 │       │ Private AZ2 │
          └──────┬──────┘       └──────┬──────┘
                 │                     │
                 └──────────┬──────────┘
                            │ PostgreSQL :5432
                            ▼
                    ┌───────────────┐
                    │     RDS       │
                    │  PostgreSQL   │
                    │ Private subnets
                    └───────────────┘

        Public Subnets
        ┌─────────────────────────────────────┐
        │ ALB + NAT Gateway                   │
        └─────────────────────────────────────┘

        Private Subnets
        ┌─────────────────────────────────────┐
        │ EC2 instances managed by ASG        │
        └─────────────────────────────────────┘

        Database Subnets
        ┌─────────────────────────────────────┐
        │ RDS PostgreSQL                      │
        └─────────────────────────────────────┘
```

### Monitoring and Alerting

```text
EC2 / ASG ───────────────┐
                         │
RDS ─────────────────────┤
                         ▼
                  CloudWatch Alarms
                         │
                         ▼
                        SNS
                         │
                         ▼
                      Email
```

### GitHub Actions → AWS

```text
GitHub Push / PR
       │
       ▼
GitHub Actions
       │
       │ OIDC token
       ▼
AWS STS
       │
       │ AssumeRoleWithWebIdentity
       ▼
GitHubActionsTerraformRole
       │
       ▼
Temporary AWS credentials
       │
       ▼
Terraform
       │
       ▼
AWS infrastructure
```

### Terraform Remote State

```text
                 S3
        ┌──────────────────────┐
        │ Terraform state      │
        │ + versioning         │
        │ + encryption         │
        │ + lockfile           │
        └──────────┬───────────┘
                   │
             ┌─────┴─────┐
             │           │
           Local      GitHub Actions
         Terraform       Terraform
```

---

## AWS Architecture Components

### 1. VPC

The VPC is distributed across two Availability Zones and contains:

- 2 public subnets
- 2 private application subnets
- 2 database subnets
- Internet Gateway
- NAT Gateway
- Separate public and private routing
- RDS DB subnet group

The application instances are private and use the NAT Gateway for outbound internet access.

---

### 2. Application Load Balancer

The ALB:

- Is internet-facing
- Accepts HTTP traffic on port 80
- Performs health checks
- Routes traffic to the EC2 target group
- Distributes traffic across healthy EC2 instances

EC2 instances are **not directly exposed to the internet**.

---

### 3. Auto Scaling Group / EC2

The application tier uses an Auto Scaling Group configured for:

```text
Minimum:  2
Desired:  2
Maximum:  4
```

Instances run in private subnets across two Availability Zones.

The Launch Template:

- Uses an Amazon Linux AMI
- Installs Apache using `user_data`
- Serves a page containing the EC2 instance ID
- Uses IMDSv2 to retrieve instance metadata
- Attaches an IAM instance profile for AWS Systems Manager

The instances are accessible through **SSM Session Manager**, so an SSH/bastion host is not required.

---

### 4. RDS PostgreSQL

The database tier uses:

```text
Engine:          PostgreSQL
Version:         16.15
Instance class:  db.t3.micro
Storage:         20 GB
Public access:   Disabled
Port:            5432
```

The RDS security group allows PostgreSQL traffic **only from the EC2 security group**.

---

## Security Design

The project intentionally separates the public, application, and database layers.

```text
Internet
   │
   ▼
ALB
   │
   ▼
Private EC2
   │
   ▼
Private RDS
```

Security controls currently implemented include:

- EC2 instances in private subnets
- RDS not publicly accessible
- EC2 security group accepts HTTP only from the ALB security group
- RDS security group accepts PostgreSQL only from the EC2 security group
- SSM Session Manager instead of SSH/bastion access
- IMDSv2 for EC2 metadata access
- GitHub Actions uses OIDC instead of long-lived AWS access keys
- GitHub OIDC trust restricted to this repository and `main`
- Terraform state stored in a dedicated S3 bucket
- S3 versioning enabled
- S3 default SSE-S3 encryption enabled
- S3 Block Public Access enabled
- Native S3 Terraform state locking enabled

---

## Monitoring and Alerting

CloudWatch and SNS are used for infrastructure monitoring.

### Current alarms

#### ASG CPU

Triggers when average ASG CPU utilization is:

```text
>= 80%
for 2 × 5-minute periods
```

#### RDS CPU

Monitors RDS CPU utilization using a CloudWatch alarm.

#### RDS Free Storage

Monitors available RDS storage and alerts when free storage falls below the configured threshold.

All current alarms use the same SNS topic for email notifications.

---

## Terraform Structure

The project uses a modular Terraform structure.

```text
self-healing-aws-infra/
│
├── .github/
│   └── workflows/
│       └── terraform.yml
│
├── modules/
│   ├── vpc/
│   ├── alb/
│   ├── asg/
│   ├── rds/
│   └── monitoring/
│
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
├── .terraform.lock.hcl
└── README.md
```

Each module follows the normal:

```text
main.tf
variables.tf
outputs.tf
```

pattern.

Terraform should always be executed from the **root project directory**, not by applying individual modules independently.

---

## Terraform Remote State

Terraform state is stored remotely in S3.

Current backend:

```text
Bucket:
self-healing-aws-infra-terraform-state-65b98806

Key:
self-healing-aws-infra/terraform.tfstate

Region:
ap-south-1
```

The S3 backend currently has:

- Versioning enabled
- SSE-S3 encryption enabled
- Block Public Access enabled
- Native S3 lockfile enabled

The currently configured infrastructure state is empty because the project's expensive AWS infrastructure is normally destroyed after development sessions to control cost.

The old local `terraform.tfstate.backup` contains state from a previous deployment and is not being treated as the current authoritative state.

---

## GitHub Actions CI

A GitHub Actions workflow exists at:

```text
.github/workflows/terraform.yml
```

Current workflow steps include:

```text
Checkout repository
        ↓
Setup Terraform 1.16.1
        ↓
GitHub OIDC authentication
        ↓
AWS identity verification
        ↓
terraform fmt -check -recursive
        ↓
terraform init -backend=false
        ↓
terraform validate
```

The CI workflow has successfully demonstrated:

- Terraform formatting validation
- Terraform initialization
- Terraform validation
- GitHub OIDC authentication
- AWS STS role assumption

The workflow currently authenticates successfully as:

```text
GitHubActionsTerraformRole
```

### Temporary debugging

A temporary OIDC debugging step is still present to display the OIDC `iss`, `aud`, and `sub` claims. It was used to discover the repository's actual immutable-ID subject format.

This step should be removed once the final authentication configuration is documented.

---

## GitHub OIDC Authentication

GitHub Actions authenticates to AWS without storing long-lived AWS access keys.

The setup uses:

```text
GitHub OIDC Provider
        ↓
AWS STS
        ↓
GitHubActionsTerraformRole
        ↓
Temporary AWS credentials
```

The IAM trust policy restricts the role to this repository and the `main` branch.

The repository uses GitHub's immutable-ID subject format:

```text
repo:<owner>@<owner-id>/<repository>@<repository-id>:ref:refs/heads/main
```

The role currently proves authentication, but its AWS permissions are still being finalized.

---

## Verification Completed

The following infrastructure tests have already been completed:

- Full Terraform stack previously applied successfully
- ALB successfully distributed traffic across two healthy EC2 instances
- Application page confirmed through the ALB
- RDS confirmed available
- EC2 → RDS TCP port 5432 connectivity confirmed
- EC2 access through SSM Session Manager confirmed
- ASG CPU alarm confirmed to read live CloudWatch data
- RDS CPU and free-storage alarms implemented
- Destroy/recreate workflow tested
- GitHub Actions CI successfully runs Terraform validation
- GitHub Actions successfully assumes the AWS IAM role through OIDC
- Local Terraform successfully uses the S3 remote backend
- `terraform plan` currently reports:

```text
Plan: 34 to add, 0 to change, 0 to destroy.
```

No new infrastructure is created by `terraform plan`.

---

## Self-Healing Design

The Auto Scaling Group is configured with:

```text
min_size = 2
desired_capacity = 2
max_size = 4
health_check_type = "ELB"
```

The intended self-healing behavior is:

```text
2 healthy instances
        │
        ▼
Instance failure / termination
        │
        ▼
ASG detects capacity or health problem
        │
        ▼
Replacement instance launched
        │
        ▼
ALB health check passes
        │
        ▼
Application returns to healthy capacity
```

### Self-healing demo status

**Not yet completed.**

The final demonstration will manually terminate one EC2 instance, observe the ASG launching a replacement, verify the replacement becomes healthy behind the ALB, and document the process with screenshots.

---

## CI/CD Roadmap

The final intended pipeline is:

```text
Pull Request
     │
     ▼
Terraform CI
 ├── fmt
 ├── init
 └── validate
     │
     ▼
Merge to main
     │
     ▼
OIDC authentication
     │
     ▼
Terraform plan
     │
     ▼
Controlled approval
     │
     ▼
Terraform apply
     │
     ▼
AWS
```

### Current status

| Area | Status |
|---|---|
| AWS multi-tier infrastructure | ✅ Complete |
| VPC / ALB / ASG / RDS | ✅ Complete |
| SSM access | ✅ Complete |
| CloudWatch + SNS monitoring | ✅ Complete |
| RDS CPU + storage alarms | ✅ Complete |
| GitHub Actions basic CI | ✅ Complete |
| GitHub OIDC provider | ✅ Complete |
| IAM trust role | ✅ Complete |
| OIDC authentication | ✅ Verified |
| S3 remote Terraform state | ✅ Complete |
| S3 versioning | ✅ Complete |
| S3 encryption | ✅ Complete |
| S3 Block Public Access | ✅ Verified |
| S3 state locking | ✅ Complete |
| GitHub role → S3 state permissions | ⏳ Next |
| Terraform plan in GitHub Actions | ⏳ |
| Terraform CD / apply | ❌ |
| Self-healing failure demo | ❌ |
| PostgreSQL authentication test | ⏸ Deferred |
| Final architecture diagram | ⏳ |
| Final README refinement | ⏳ |
| Final end-to-end verification | ❌ |

---

## Cost Management

The AWS Free Tier period for the account has expired, so the project is being developed with a limited AWS credit balance.

The project therefore follows a cost-conscious workflow:

```text
Build / test infrastructure
        ↓
Verify functionality
        ↓
Document results
        ↓
terraform destroy
```

The Terraform state S3 bucket is intended to remain because its storage/request cost at this project's scale is negligible compared with continuously running compute/network/database resources.

Particular attention should be paid to resources such as:

- NAT Gateway
- RDS
- EC2
- ALB
- EBS

Do not leave the application infrastructure running unnecessarily.

---

## Useful Commands

### Validate Terraform locally

```bash
terraform fmt -check -recursive
terraform init
terraform validate
terraform plan
```

### Apply infrastructure

```bash
terraform apply
```

### Destroy infrastructure after a session

```bash
terraform destroy
```

### Check Terraform state

```bash
terraform state list
```

### Check the current AWS identity

```bash
aws sts get-caller-identity
```

---

## Lessons Learned

This project has already exposed several practical DevOps lessons:

- Terraform modules should be managed through the root configuration and shared state.
- `terraform validate` checks Terraform's own configuration validity but does not guarantee AWS will accept every semantic value.
- CloudWatch alarms use SNS for email notification delivery.
- EC2 instances can be managed through SSM instead of exposing SSH.
- Private subnets can provide outbound internet access through NAT without making application instances public.
- GitHub Actions OIDC separates authentication from authorization.
- OIDC provider registration does not grant AWS permissions; the IAM role trust policy controls who can assume the role, while the role's permissions control what it can do.
- Exact OIDC claims matter; the trust policy must match the actual GitHub token subject.
- CI is useful even for small infrastructure projects because it catches problems such as Terraform formatting errors before deployment.
- Remote Terraform state is necessary when multiple execution environments, such as a developer workstation and GitHub Actions, need to work with the same infrastructure.

---

## Project Status

This README intentionally reflects the **current development state**.

It will be updated as the remaining milestones are completed, especially:

1. GitHub Actions S3 state permissions
2. `terraform plan` in CI
3. Controlled Terraform apply / CD
4. Self-healing failure demonstration
5. PostgreSQL authentication verification
6. Final architecture diagram
7. Final end-to-end validation
