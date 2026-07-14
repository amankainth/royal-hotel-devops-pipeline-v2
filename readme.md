# Royal Hotel DevOps Pipeline

End-to-end CI/CD pipeline that provisions AWS infrastructure using Terraform and configures it with Ansible, orchestrated by Jenkins.

## Architecture

## Prerequisites

- Jenkins server with:
  - Java 21, Git, Terraform, Ansible installed
  - IAM role with EC2, S3, DynamoDB permissions
- AWS account
- GitHub webhook (optional for auto-trigger)

## One-Time Bootstrap

Before first pipeline run, create the S3 backend:

```bash
cd bootstrap
bash setup-backend.sh

This creates:

S3 bucket: royal-hotel-tf-state-bucket
DynamoDB table: royal-hotel-tf-locks

----------------------------------------------------------------------
royal-hotel-devops-pipeline-v2/
│
├── README.md
├── Jenkinsfile
├── Jenkinsfile.destroy
├── terraform/
├── ansible/
└── bootstrap/
--------------------------------------------------------------------------
