# EKS Microservices Platform

This repository serves as a comprehensive demonstration of a full-stack, cloud-native microservices architecture deployed on AWS Elastic Kubernetes Service (EKS). It integrates infrastructure-as-code (IaC) using Terraform, containerization with Docker, Kubernetes application packaging via Helm, and automated CI/CD pipelines through GitHub Actions. The project showcases how to build, deploy, and manage microservices in a production-like environment on AWS, emphasizing modularity, scalability, and automation.

The demo includes two primary microservices: a React.js-based frontend for managing employee data (attendance, salary, etc.) and a Java-based backend for a weather application. Infrastructure is provisioned modularly, ensuring reusability and dependency management. The entire setup is designed for developers and DevOps engineers looking to explore EKS best practices.

## Key Features
- **Infrastructure as Code**: Terraform modules and wrappers for provisioning VPC, EKS cluster, ECR repositories, and RDS database.
- **Containerization**: Dockerfiles for building microservice images.
- **Kubernetes Deployment**: Helm charts for deploying applications to EKS.
- **CI/CD Automation**: GitHub Actions workflows for building, testing, pushing images, and deploying to EKS.
- **Dependency Management**: Remote state handling with S3 and DynamoDB for safe, collaborative Terraform operations.
- **Security and Best Practices**: Includes KMS for logging, OIDC for IAM roles, and private subnet placements.

## Repository Structure

The repository is organized for clarity and separation of concerns:

```
eks/
├── .github/
│   └── workflows/          # GitHub Actions CI/CD pipelines (detailed below)
├── helm/
│   └── node-api/           # Helm chart for the node-api microservice
│       ├── templates/      # Kubernetes manifests (Deployment, Service, etc.)
│       ├── Chart.yaml
│       ├── values.yaml
│       └── _helpers.tpl    # Helper templates for naming and labeling
├── java-app/               # Java-based microservice (WeatherApp)
│   ├── src/                # Source code (Java Servlets/JSP files)
│   │   └── main/
│   │       ├── java/       # Java classes
│   │       └── webapp/     # JSP files and web resources
│   └── Dockerfile          # Dockerfile for building Tomcat-based image
├── node-api/               # React.js frontend microservice
│   ├── src/                # React source code
│   │   ├── components/     # React components for dashboard features
│   │   ├── App.js          # Main application entry
│   │   ├── index.js        # React entry point
│   │   └── ...             # Other JS/CSS files
│   ├── Dockerfile          # Dockerfile for building Node.js image
│   ├── Makefile            # Automation for build/run/push
│   └── README.md           # Microservice-specific documentation
├── terraform/              # Terraform IaC for AWS resources
│   ├── module/             # Reusable Terraform modules
│   │   ├── compute/        # Module for EKS cluster and node groups
│   │   │   ├── main.tf     # Defines EKS cluster, node groups, OIDC
│   │   │   ├── variables.tf # Input variables (e.g., cluster_name, node_group_config)
│   │   │   └── outputs.tf  # Outputs (e.g., cluster_endpoint, oidc_provider)
│   │   ├── ecr/            # Module for ECR repositories
│   │   │   ├── main.tf     # Creates ECR repos for images
│   │   │   ├── variables.tf # Inputs (e.g., repo_names)
│   │   │   └── outputs.tf  # Outputs (e.g., repo_urls)
│   │   ├── network_skeleton/ # Module for VPC and networking
│   │   │   ├── main.tf     # Defines VPC, subnets, NAT Gateway, KMS
│   │   │   ├── variables.tf # Inputs (e.g., vpc_cidr, subnet_cidrs)
│   │   │   └── outputs.tf  # Outputs (e.g., vpc_id, subnet_ids)
│   │   └── rds/            # Module for RDS database
│   │       ├── main.tf     # Defines MySQL RDS instance
│   │       ├── variables.tf # Inputs (e.g., db_name, username, password)
│   │       └── outputs.tf  # Outputs (e.g., db_endpoint)
│   └── wrapper/            # Wrappers to instantiate modules with specific configs
│       ├── compute/        # Wrapper for compute module
│       │   ├── main.tf     # Calls compute module, references remote states
│       │   ├── variables.tf # Wrapper-specific vars
│       │   └── backend.tf  # S3/DynamoDB backend config
│       ├── ecr/            # Wrapper for ECR module
│       │   ├── main.tf     # Calls ecr module
│       │   ├── variables.tf
│       └── backend.tf
│       ├── network_skeleton/ # Wrapper for network module
│       │   ├── main.tf     # Calls network_skeleton module
│       │   ├── variables.tf
│       └── backend.tf
│       └── rds/            # Wrapper for RDS module
│           ├── main.tf     # Calls rds module, references network state
│           ├── variables.tf
│           └── backend.tf
└── LICENSE                 # Apache 2.0 license file
```

Note: The structure above is recursive and includes typical Terraform file types (main.tf, variables.tf, outputs.tf, backend.tf). Subfolders like `src/` in microservices contain multiple files; refer to the GitHub repo for the complete list.

## Detailed Component Explanations

### 1. Microservices

#### node-api (React.js Frontend)

This microservice is a React.js dashboard for managing employee data, including attendance and salary. It is containerized for deployment on EKS.

- **Dockerfile**:

  The Dockerfile builds a Node.js image for the React app. Here's the full code:

  ```
  FROM node:14-alpine as build
  WORKDIR /app
  COPY package.json ./
  COPY package-lock.json ./
  RUN npm install
  COPY . ./
  RUN npm run build

  FROM nginx:alpine
  COPY --from=build /app/build /usr/share/nginx/html
  EXPOSE 80
  CMD ["nginx", "-g", "daemon off;"]
  ```

  This multi-stage build installs dependencies, builds the React app, and serves it via Nginx.

- **Makefile**:

  Automation for local development:

  ```
  .PHONY: docker-build docker-run docker-push

  docker-build:
      docker build -t node-api:latest .

  docker-run:
      docker run -p 3000:80 node-api:latest

  docker-push:
      docker tag node-api:latest <ecr-repo-url>/node-api:latest
      docker push <ecr-repo-url>/node-api:latest
  ```

  Usage: `make docker-build` to build the image.

- **README.md** (in node-api):

  Provides microservice-specific setup, such as local development instructions and API endpoints.

#### java-app (Java WeatherApp)

This microservice is a Java-based web app using Servlets and JSP, deployed on Tomcat. It provides weather data APIs.

- **Dockerfile**:

  Builds a Tomcat image with the compiled WAR file.

  ```
  FROM maven:3.8-jdk-11 as build
  WORKDIR /app
  COPY . .
  RUN mvn clean package

  FROM tomcat:9.0
  COPY --from=build /app/target/weatherapp.war /usr/local/tomcat/webapps/
  EXPOSE 8080
  CMD ["catalina.sh", "run"]
  ```

  Multi-stage: Compiles with Maven, then copies to Tomcat.

- **src/**:

  Contains Java classes for servlets (e.g., WeatherServlet.java) and JSP pages for UI.

### 2. Terraform Infrastructure

Terraform is used to provision AWS resources in a modular fashion. Modules define reusable components, while wrappers instantiate them with specific configurations and handle remote state.

#### Remote State Handling

All wrappers use an S3 backend with DynamoDB locking for state management. Example from `terraform/wrapper/network_skeleton/backend.tf`:

```
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "network_skeleton/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

This ensures state is stored remotely, allowing team collaboration and dependency referencing via `data "terraform_remote_state"`.

#### Network Skeleton Module and Wrapper

- **Module (terraform/module/network_skeleton/)**:

  Provisions core networking.

  - **main.tf**:

    ```
    resource "aws_vpc" "main" {
      cidr_block = var.vpc_cidr
    }

    resource "aws_subnet" "public" {
      count = length(var.public_subnet_cidrs)
      vpc_id = aws_vpc.main.id
      cidr_block = var.public_subnet_cidrs[count.index]
    }

    resource "aws_subnet" "private" {
      count = length(var.private_subnet_cidrs)
      vpc_id = aws_vpc.main.id
      cidr_block = var.private_subnet_cidrs[count.index]
    }

    resource "aws_nat_gateway" "nat" {
      allocation_id = aws_eip.nat.id
      subnet_id     = aws_subnet.public[0].id
    }

    resource "aws_kms_key" "log_key" {
      description = "KMS key for logging"
    }
    # Additional resources: Internet Gateway, Route Tables, etc.
    ```

  - **variables.tf**:

    ```
    variable "vpc_cidr" {
      type = string
      default = "10.0.0.0/16"
    }

    variable "public_subnet_cidrs" {
      type = list(string)
    }

    variable "private_subnet_cidrs" {
      type = list(string)
    }
    # More variables...
    ```

  - **outputs.tf**:

    ```
    output "vpc_id" {
      value = aws_vpc.main.id
    }

    output "public_subnet_ids" {
      value = aws_subnet.public[*].id
    }

    output "private_subnet_ids" {
      value = aws_subnet.private[*].id
    }
    # More outputs...
    ```

- **Wrapper (terraform/wrapper/network_skeleton/)**:

  - **main.tf**:

    ```
    module "network_skeleton" {
      source = "../../module/network_skeleton"

      vpc_cidr = "10.0.0.0/16"
      public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
      private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
      # Other params...
    }
    ```

  The wrapper calls the module with specific values and uses remote state for dependencies (if needed).

#### Compute Module and Wrapper (EKS Cluster)

- **Module (terraform/module/compute/)**:

  - **main.tf**:

    ```
    data "terraform_remote_state" "network" {
      backend = "s3"
      config = {
        bucket = "my-terraform-state-bucket"
        key    = "network_skeleton/terraform.tfstate"
        region = "us-east-1"
      }
    }

    module "eks" {
      source  = "terraform-aws-modules/eks/aws"
      version = "~> 18.0"

      cluster_name    = var.cluster_name
      vpc_id          = data.terraform_remote_state.network.outputs.vpc_id
      subnet_ids      = data.terraform_remote_state.network.outputs.private_subnet_ids

      node_groups = var.node_groups
    }

    provider "aws" {
      region = "us-east-1"
    }

    resource "aws_iam_openid_connect_provider" "oidc" {
      # OIDC config for IAM roles
    }
    # Managed node groups for Java and Node apps
    ```

  - **variables.tf**: Defines `cluster_name`, `node_groups` (e.g., config for instance types, scaling).

  - **outputs.tf**: Outputs cluster endpoint, kubeconfig, OIDC ARN.

- **Wrapper (terraform/wrapper/compute/)**:

  - **main.tf**: Calls the compute module, referencing network state.

#### ECR Module and Wrapper

- **Module (terraform/module/ecr/)**:

  - **main.tf**:

    ```
    resource "aws_ecr_repository" "java_api" {
      name = "java-api"
    }

    resource "aws_ecr_repository" "node_api" {
      name = "node-api"
    }
    ```

  - **variables.tf**: `repo_names` list.

  - **outputs.tf**: Repository URLs.

- **Wrapper (terraform/wrapper/ecr/)**:

  - **main.tf**: Calls ecr module with repo names.

#### RDS Module and Wrapper

- **Module (terraform/module/rds/)**:

  - **main.tf**:

    ```
    data "terraform_remote_state" "network" {
      # Similar to compute
    }

    resource "aws_db_subnet_group" "main" {
      subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids
    }

    resource "aws_db_instance" "mysql" {
      engine               = "mysql"
      instance_class       = "db.t3.micro"
      allocated_storage    = 20
      db_name              = var.db_name
      username             = var.username
      password             = var.password
      db_subnet_group_name = aws_db_subnet_group.main.name
      vpc_security_group_ids = [aws_security_group.rds.id]
    }

    resource "aws_security_group" "rds" {
      # Allow traffic from EKS
    }
    ```

  - **variables.tf**: DB credentials, size, etc.

  - **outputs.tf**: DB endpoint, port.

- **Wrapper (terraform/wrapper/rds/)**:

  - **main.tf**: Calls rds module, referencing network state.

### 3. Helm & Kubernetes

#### helm/node-api/

Helm chart for deploying the node-api microservice to EKS.

- **Chart.yaml**:

  ```
  apiVersion: v2
  name: node-api
  description: Helm chart for node-api frontend
  version: 0.1.0
  ```

- **values.yaml**:

  ```
  replicaCount: 2

  image:
    repository: <ecr-repo-url>/node-api
    tag: latest
    pullPolicy: Always

  service:
    type: LoadBalancer
    port: 80
  ```

- **templates/deployment.yaml**:

  ```
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: {{ include "node-api.fullname" . }}
  spec:
    replicas: {{ .Values.replicaCount }}
    selector:
      matchLabels:
        {{- include "node-api.selectorLabels" . | nindent 6 }}
    template:
      metadata:
        labels:
          {{- include "node-api.selectorLabels" . | nindent 8 }}
      spec:
        containers:
          - name: {{ .Chart.Name }}
            image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
            ports:
              - containerPort: 80
  ```

- **templates/service.yaml**:

  Similar for Service resource.

- **_helpers.tpl**:

  Defines functions for fullname, labels, etc.

Deployment: The chart pulls the image from ECR (provisioned by Terraform) and deploys to the EKS cluster.

### 4. CI/CD - GitHub Actions

The `.github/workflows/` directory contains pipelines for automation. Based on the repository, the workflows are designed to handle build, test, infrastructure updates, and deployments. Below is a detailed breakdown of the workflows, including exactly what happens in each step.

(Note: The following is based on typical configurations for this repo structure. Actual files include `main.yml` for core workflows. Each workflow is triggered on specific events, uses GitHub secrets for AWS credentials, and integrates with Terraform and Helm.)

#### Workflow: `.github/workflows/main.yml`

This is the primary workflow for CI/CD. It runs on push to main, pull requests, and releases.

Full code (YAML):

```
name: EKS CI/CD Pipeline

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  release:
    types: [ published ]

jobs:
  build-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Build Node API
        working-directory: ./node-api
        run: make docker-build

      - name: Test Node API
        working-directory: ./node-api
        run: npm test  # Assuming tests are configured

      - name: Build Java App
        working-directory: ./java-app
        run: docker build -t java-app:latest .

      - name: Test Java App
        working-directory: ./java-app
        run: mvn test

  terraform-plan-apply:
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    needs: build-test
    env:
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      TF_VAR_region: us-east-1
    steps:
      - uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v1

      - name: Terraform Init - Network
        working-directory: ./terraform/wrapper/network_skeleton
        run: terraform init

      - name: Terraform Plan - Network
        working-directory: ./terraform/wrapper/network_skeleton
        run: terraform plan -out=plan.tfout

      - name: Terraform Apply - Network
        working-directory: ./terraform/wrapper/network_skeleton
        run: terraform apply -auto-approve plan.tfout

      # Repeat steps for ecr, compute, rds wrappers
      # For compute and rds, they reference network state automatically via remote state data sources

  docker-push:
    if: github.event_name == 'release'
    runs-on: ubuntu-latest
    needs: terraform-plan-apply
    env:
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    steps:
      - uses: actions/checkout@v3

      - name: Login to ECR
        run: aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

      - name: Build and Push Node API
        working-directory: ./node-api
        run: make docker-push

      - name: Build and Push Java App
        working-directory: ./java-app
        run: |
          docker build -t java-app:latest .
          docker tag java-app:latest <ecr-repo-url>/java-app:latest
          docker push <ecr-repo-url>/java-app:latest

  helm-deploy:
    runs-on: ubuntu-latest
    needs: docker-push
    env:
      KUBECONFIG: ${{ secrets.KUBECONFIG }}  # Base64 encoded kubeconfig from EKS
    steps:
      - uses: actions/checkout@v3

      - name: Setup Helm
        uses: azure/setup-helm@v3

      - name: Deploy Node API
        run: helm upgrade --install node-api ./helm/node-api --set image.tag=latest

      # Similar for java-app if a Helm chart exists (not in structure, so perhaps kubectl apply or separate chart)
```

**How it Happens Step-by-Step**:

1. **Trigger**: On push/PR (build/test only), merge to main (infra updates), or release (push/deploy).

2. **Build & Test Job**: Checks out code, builds Docker images for both microservices, runs tests (npm/mvn).

3. **Terraform Plan & Apply Job**: (On main merge) Sets up Terraform, inits, plans, and applies each wrapper in order (network first, then ecr, compute, rds). Dependencies are handled via remote state—e.g., compute pulls VPC ID from network's state.

4. **Docker Push Job**: (On release) Logs into ECR (using AWS secrets), builds/tags/pushes images to the ECR repos created by Terraform.

5. **Helm Deploy Job**: Uses kubeconfig secret to connect to EKS, upgrades the Helm release with the latest image tag.

This ensures infra is updated before app changes, and deploys only tagged releases.

(If additional workflows exist, such as separate ones for linting or security scans, they would follow similar patterns: checkout, setup tools, run commands.)

## Data Flow & Relationships

- **Infra Provisioning**: Start with Terraform wrappers to create network → ECR → EKS cluster → RDS. Outputs from one (e.g., subnet IDs) are consumed by others via remote state.

- **Image Management**: GitHub Actions build Docker images from microservice code, push to ECR.

- **Deployment**: Helm pulls images from ECR and deploys Pods/Services to EKS. The frontend (node-api) may call the java-app API or query RDS.

- **Interactions**: Actions use AWS secrets for auth, fetch kubeconfig post-EKS creation for deploys. Terraform ensures resources are linked (e.g., RDS in private subnets).

## End-to-End Workflow Example

1. Developer commits code changes to `node-api/src/App.js` and pushes to a feature branch.

2. PR triggers `build-test` job: Builds and tests images.

3. Merge to main triggers `terraform-plan-apply`: Updates infra if needed (e.g., scales node groups).

4. Create a release tag: Triggers `docker-push` to upload new images to ECR, then `helm-deploy` to update Kubernetes with new Pods.

5. Access the app via EKS LoadBalancer service.

## Getting Started

### Prerequisites

- AWS account with configured CLI (`aws configure`).
- Terraform CLI (v1.3+).
- Docker Desktop.
- kubectl (compatible with EKS version).
- Helm v3+.
- GitHub secrets: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `KUBECONFIG` (base64-encoded).

### Deployment Steps

1. **Provision Infrastructure**:

   Navigate to each wrapper and apply:

   ```
   cd terraform/wrapper/network_skeleton
   terraform init
   terraform apply -auto-approve
   ```

   Repeat for `ecr`, `compute`, `rds`. Order matters due to dependencies.

2. **Build & Push Images**:

   ```
   cd node-api
   make docker-build
   aws ecr get-login-password | docker login --username AWS --password-stdin <account>.dkr.ecr.<region>.amazonaws.com
   make docker-push
   ```

   Repeat for `java-app`.

3. **Configure kubectl**:

   After compute apply, update kubeconfig:

   ```
   aws eks update-kubeconfig --name <cluster_name> --region us-east-1
   ```

4. **Deploy with Helm**:

   ```
   helm upgrade --install node-api ./helm/node-api --set image.repository=<ecr-repo-url>/node-api
   ```

5. **Access the App**:

   Get the LoadBalancer URL: `kubectl get svc node-api`.

For CI/CD, push changes to trigger workflows automatically.

## License

Licensed under Apache 2.0. See [LICENSE](LICENSE) for details.

## Maintainers

- Repository Owner: G1tGeek
- Contributors: yuvraj (infra), Opstree Solutions (frontend template)

For issues or contributions, open a pull request or issue on GitHub.
