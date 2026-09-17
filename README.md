# DevOps Assignment

## Overview

This project demonstrates an end-to-end DevOps workflow for deploying and operating a containerized healthcare application on AWS.

The implementation covers infrastructure provisioning with Terraform, configuration using Ansible, CI/CD using Jenkins, containerization with Docker, deployment using Kubernetes, and infrastructure monitoring using Prometheus and Grafana.

## Architecture

```text
Developer
   |
 GitHub
   |
 Jenkins CI/CD
   |
 Maven Build & Test
   |
 Docker Build
   |
 Container Registry
   |
 Kubernetes Cluster
   |
 Application
   |
 Prometheus + Grafana
```

AWS infrastructure is provisioned using Terraform with:

* VPC
* Public and private subnets
* EC2 instances
* Application Load Balancer
* Security Groups
* Amazon ECR
* RDS PostgreSQL

## Technology Stack

* **Cloud:** AWS
* **Infrastructure as Code:** Terraform
* **Configuration Management:** Ansible
* **CI/CD:** Jenkins
* **Version Control:** Git / GitHub
* **Build:** Maven
* **Containers:** Docker
* **Container Registry:** Docker Hub / Amazon ECR
* **Orchestration:** Kubernetes
* **Monitoring:** Prometheus, Node Exporter, Grafana
* **Database:** PostgreSQL (Amazon RDS)

## Infrastructure Provisioning

Terraform is used to provision and manage the AWS infrastructure.

The `terraform/` directory contains:

```text
terraform/
├── main.tf
├── provider.tf
├── variables.tf
└── outputs.tf
```
<img width="1366" height="768" alt="image" src="https://github.com/user-attachments/assets/36ad730a-6e1d-4abc-a8c1-c4adf5616352" />

Configurable parameters such as AWS region, VPC CIDR, availability zones, database configuration, and EC2 instance type are defined in `variables.tf`.

Key resource outputs include the VPC ID, ALB DNS name, ECR repository URL, EC2 private IPs, and RDS endpoint.

### Terraform Commands

```bash
cd terraform

terraform init
terraform validate
terraform plan
terraform apply
```

Terraform state is kept out of source control using `.gitignore`. For a production implementation, remote state with locking would be preferred.
<img width="981" height="173" alt="image" src="https://github.com/user-attachments/assets/2810a361-57c2-4412-8086-c4e2a18b7779" />

## Ansible Configuration Management

Ansible was used to automate server configuration and application environment setup across the healthcare project infrastructure.
<img width="981" height="513" alt="image" src="https://github.com/user-attachments/assets/1bd99598-acba-4daf-93ad-57aa75265cb2" />

## CI/CD Pipeline

Jenkins automates the application build and deployment workflow.

Pipeline flow:

```text
GitHub Push
    ↓
SCM Checkout
    ↓
Maven Build/Test
    ↓
Docker Build
    ↓
Container Registry
    ↓
Kubernetes Deployment
```
<img width="990" height="405" alt="image" src="https://github.com/user-attachments/assets/650bbac0-cca4-4b43-8a4b-366d6a74f7d7" />
<img width="979" height="524" alt="image" src="https://github.com/user-attachments/assets/337a07f1-6520-4bf9-bfa4-14357d7d218d" />
<img width="971" height="498" alt="image" src="https://github.com/user-attachments/assets/6b817aa8-609f-430f-8ae7-0edba258cab1" />
<img width="972" height="522" alt="image" src="https://github.com/user-attachments/assets/3d7be0b7-01c7-4146-a27d-08ce362e75a5" />

### GitHub webhook integration is used to trigger the Jenkins pipeline when code is pushed.
<img width="972" height="523" alt="image" src="https://github.com/user-attachments/assets/6ff95eab-9c82-45d9-937a-4d8ade63a580" />

### Jenkins credentials are used for registry authentication rather than storing credentials in the source code.
<img width="973" height="511" alt="image" src="https://github.com/user-attachments/assets/d315395b-f4fc-4854-b006-cebeed13e4a8" />

## Kubernetes

The application is deployed to a Kubernetes cluster using Kubernetes manifests.

Example commands:

```bash
kubectl apply -f kubernetesdeploy.yaml
kubectl get pods
kubectl get services
```
<img width="979" height="514" alt="image" src="https://github.com/user-attachments/assets/23ca8798-51f7-4060-a7d3-5215bbb21d4e" />

## Monitoring

Prometheus and Node Exporter are used to collect infrastructure metrics from the servers, with Grafana providing visualization.
<img width="980" height="509" alt="image" src="https://github.com/user-attachments/assets/24f9c2c3-8ef3-4664-a393-c1f4f3248fb1" />

The monitoring setup includes dashboards for:

* CPU utilization
  <img width="968" height="512" alt="image" src="https://github.com/user-attachments/assets/42b1c8ff-791c-4a44-9683-8b73067b6bb5" />

* Memory utilization
  <img width="980" height="519" alt="image" src="https://github.com/user-attachments/assets/66f9ff61-92f7-4f57-ab9b-8d3b5ce04d29" />

* Disk utilization
  <img width="980" height="515" alt="image" src="https://github.com/user-attachments/assets/4a520fea-f79e-4a18-99eb-9e0c02b64e2d" />


Email notifications are also configured for Jenkins build/deployment status such as successful, failed, or unstable executions.
<img width="992" height="486" alt="image" src="https://github.com/user-attachments/assets/cb89098b-1d53-453f-aaff-c094a1dc71f3" />

## Security Considerations

* AWS resources are protected using security groups.
* Application and database access is restricted through security-group rules.
* Sensitive credentials are stored through Jenkins credentials rather than committed to Git.
* Terraform state files, plans, and private keys are excluded from the repository.
* Production deployments should use least-privilege IAM policies and managed secrets.

## Backup & Cost Optimization

* Amazon RDS backup retention is configured for database recovery.
* Small instance types are used where appropriate to control development/assignment costs.
* Resources should be stopped or removed when they are no longer required.
* A single NAT Gateway is used in the current Terraform configuration to reduce infrastructure cost; production environments may use a more highly available design.

## Assignment Notes / Future Improvements

The current implementation provides the core infrastructure, deployment, and infrastructure-monitoring workflow.

For a production-grade CI/CD implementation, the following can be added:

* Pull-request based automated validation
* Separate staging and production deployment stages
* Manual production approval
* Dependency vulnerability scanning
* Container image vulnerability scanning
* Centralized application/system/access logging
* Application-level request, error, and latency metrics
* Database monitoring dashboards
* Remote Terraform state with locking

These are identified as improvements rather than being represented as already implemented features.

## Repository Structure

```text
.
├── src/
├── Dockerfile
├── pom.xml
├── ansible-playbook.yml
├── kubernetesdeploy.yaml
├── terraform/
│   ├── main.tf
│   ├── provider.tf
│   ├── variables.tf
│   └── outputs.tf
├── mvnw
└── README.md
```

## Summary

This project demonstrates infrastructure provisioning, configuration management, CI/CD automation, containerization, Kubernetes deployment, and monitoring using AWS and open-source DevOps tools.
