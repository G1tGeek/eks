# EKS Microservices Platform

This repository is a full-stack, cloud-native microservices demo built for AWS EKS (Elastic Kubernetes Service). It leverages Terraform for infrastructure-as-code, Helm for Kubernetes application packaging, Docker for containerization, and GitHub Actions for CI/CD automation.

---

## Repository Structure

```
eks/
├── node-api/           # React.js frontend microservice
│   ├── src/
│   ├── Dockerfile
│   ├── Makefile
│   └── README.md
├── java-app/           # Java Servlet/JSP microservice
│   ├── src/
│   └── Dockerfile
├── terraform/          # Infrastructure-as-Code
│   ├── module/
│   │   ├── network_skeleton/
│   │   ├── compute/
│   │   ├── ecr/
│   │   └── rds/
│   └── wrapper/
│       ├── network_skeleton/
│       ├── compute/
│       ├── ecr/
│       └── rds/
├── helm/               # Helm charts for Kubernetes
│   └── node-api/
└── .github/workflows/  # GitHub Actions CI/CD pipelines
```

---

## Main Components

### 1. **Microservices**
- **node-api**: React.js frontend dashboard for employee/attendance/salary management. Containerized via Docker; Makefile provides build/run automation.
- **java-app**: Java-based WeatherApp microservice, built with Servlets/JSP, containerized for Tomcat deployment.

### 2. **Terraform Infrastructure**

The infrastructure is modularized and managed via wrappers and reusable modules:

#### - **Network Skeleton**
  - Creates VPC, public/private subnets, NAT Gateway, and KMS key for logging.
  - Outputs VPC IDs, subnet IDs, etc.
  - Example: `terraform/wrapper/network_skeleton/main.tf` uses `module/network_skeleton` to provision networking.

#### - **Compute (EKS Cluster)**
  - Provisions an EKS cluster, managed node groups (for Java and NodeJS apps), OIDC provider for IAM roles.
  - Dynamically links to network outputs via remote S3 state.
  - Example: `terraform/wrapper/compute/main.tf` uses `module/compute` for EKS setup.

#### - **ECR (Elastic Container Registry)**
  - Creates ECR repositories for container images (`java-api` and `node-api`).
  - Outputs repository URLs.
  - Example: `terraform/wrapper/ecr/main.tf` uses `module/ecr`.

#### - **RDS (Database)**
  - Provisions an RDS MySQL instance, private subnet placement, network connection.
  - Example: `terraform/wrapper/rds/main.tf` uses `module/rds`.

#### - **Remote State Handling**
  - Each wrapper uses S3/DynamoDB for Terraform state and locking, ensuring safe collaboration and dependency management.

---

## Helm & Kubernetes

- **helm/node-api/**: Helm chart for deploying the node-api frontend to Kubernetes. 
  - Includes helpers for naming, labeling, and release management.

---

## CI/CD - GitHub Actions

> *(Note: The actual workflow YAML files were not present in tool output, but typical patterns for such a repo are described below. Please adjust as needed for your actual workflow files.)*

### Example Workflow: `.github/workflows/main.yml`
- **Build & Test**: On push/PR, builds Docker images for node-api and java-app, runs tests.
- **Terraform Plan & Apply**: On merge to main, runs Terraform plan/apply for wrappers (network, compute, ecr, rds) to update infrastructure.
- **Docker Push**: On release/tag, builds and pushes images to ECR repositories.
- **Helm Deploy**: Deploys updated images to EKS via Helm, using the latest ECR image tags.

### How GitHub Actions & Terraform Interact

- **ECR Creation**: Terraform creates ECR repos. GitHub Actions use these URLs to push built Docker images.
- **Cluster Management**: Terraform builds the VPC/network and EKS cluster. Actions can deploy and update services once the cluster is up.
- **State Coordination**: Actions may trigger Terraform runs to update infra, and then trigger app deploys.
- **Secrets/Config**: Actions fetch AWS credentials, ECR login, and kubeconfigs, usually via GitHub secrets.

---

## Data Flow & Relationships

1. **Infra Provisioning**: Terraform modules (via wrappers) provision network, EKS, ECR, RDS.
2. **Image Build & Push**: GitHub Actions build microservice containers, push to ECR.
3. **Deployment**: Helm charts deploy containers from ECR to EKS cluster.
4. **Service Interaction**: Frontend (node-api) communicates with backend APIs (Java or other microservices), all running inside EKS.
5. **State Sharing**: S3 state files ensure modules (network, compute, rds) are linked and can reference outputs.

---

## Example: End-to-End Workflow

1. *Developer pushes code to node-api or java-app.*
2. **GitHub Actions**:
    - Build Docker image.
    - Run tests.
    - Push image to ECR (created by Terraform).
    - Trigger Helm upgrade to EKS cluster.
3. *Infra updates (network, compute, ecr, rds) are managed via Terraform and coordinated in state files.*

---

## Getting Started

### Prerequisites
- AWS account + CLI
- Terraform CLI (>=1.3)
- Docker
- Kubectl & Helm
- GitHub repository secrets: AWS credentials, ECR info

### Deploy Steps

1. **Provision Infrastructure**:
    ```sh
    cd terraform/wrapper/network_skeleton
    terraform init && terraform apply
    cd ../ecr
    terraform init && terraform apply
    cd ../compute
    terraform init && terraform apply
    cd ../rds
    terraform init && terraform apply
    ```
2. **Build & Push Images**:
    ```sh
    cd node-api
    make docker-build
    make docker-push
    # Repeat for java-app
    ```
3. **Deploy to EKS**:
    ```sh
    helm upgrade --install node-api ./helm/node-api
    ```

> For automated CI/CD, ensure workflow YAMLs in `.github/workflows/` are configured for build/test/deploy.

---

## License

Apache 2.0 (see LICENSE).

---

## Maintainers

- Owner: [G1tGeek](https://github.com/G1tGeek)
- Infra: yuvraj
- Frontend: Opstree Solutions (template origin)

---

## References

- [Terraform AWS Modules](https://github.com/terraform-aws-modules)
- [Helm Documentation](https://helm.sh/docs/)
- [EKS Getting Started](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html)
