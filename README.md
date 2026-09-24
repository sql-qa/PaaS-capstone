# PaaS Capstone — Hybrid Kubernetes Deployment (GCP/GKE)

A hybrid Platform-as-a-Service capstone project demonstrating infrastructure
provisioning and application deployment across a **local Kubernetes cluster**
and **Google Kubernetes Engine (GKE)**, with infrastructure defined as code
via Terraform and CI/CD tooling (Jenkins) deployed as part of the stack.

## Overview

This project provisions and deploys a hybrid Kubernetes environment:

- A **local Kubernetes cluster** runs Jenkins and Nginx workloads for
  development/CI tooling.
- **Terraform** provisions a **GKE cluster** on Google Cloud.
- A demo **Nginx application** is deployed to GKE, scaled, and exposed via
  a LoadBalancer service.
- Bash scripts automate the end-to-end demo: starting local services,
  applying Terraform, connecting to GKE, deploying the app, and reporting
  the final status (cluster nodes, service endpoints, external IP).

## Tech Stack

- **Infrastructure as Code:** Terraform
- **Container Orchestration:** Kubernetes (local cluster + GKE)
- **CI/CD:** Jenkins (deployed via Kubernetes manifests)
- **Web Server / Demo App:** Nginx
- **Cloud Platform:** Google Cloud Platform (GKE)
- **Automation:** Bash

## Project Structure

```
PaaS-capstone/
├── README.md
├── .gitignore
├── k8s/
│   ├── jenkins/            # Kubernetes manifests to deploy Jenkins
│   │   ├── jenkins-01-serviceAccount.yaml
│   │   ├── jenkins-02-volume.yaml
│   │   ├── jenkins-03-deployment.yaml
│   │   ├── jenkins-04-service.yaml
│   │   └── jenkins-ingress.yaml
│   └── nginx/               # Kubernetes manifests to deploy Nginx
│       ├── nginx-ingress.yaml
│       ├── nginx-test-deployment.yaml
│       └── nginx-test-service.yaml
├── scripts/                 # Automation scripts
│   ├── check-cluster.sh
│   ├── cleanup.sh
│   ├── demo.sh
│   ├── deploy.sh
│   ├── start-demo.sh        # Full end-to-end demo runner
│   └── verify.sh
└── terraform/                # GKE infrastructure as code
    ├── main.tf
    ├── variables.tf
    ├── terraform.tfvars.example
    └── .terraform.lock.hcl
```

## Prerequisites

- `kubectl`
- `terraform`
- `gcloud` CLI, authenticated (`gcloud auth login`)
- A GCP project with billing enabled
- A local Kubernetes cluster available (e.g. via `kubeadm`, `minikube`, or similar)

## Setup

1. **Clone the repo**
   ```bash
   git clone https://github.com/sql-qa/PaaS-capstone.git
   cd PaaS-capstone
   ```

2. **Configure Terraform variables**

   Copy the example file and fill in your own GCP project details:
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   ```
   Edit `terraform.tfvars` with your actual `project_id`, `region`, and `zone`.

3. **Authenticate with GCP**
   ```bash
   gcloud auth login
   gcloud config set project YOUR_PROJECT_ID
   ```

## Deployment

### Provision the GKE cluster
```bash
cd terraform
terraform init
terraform apply
```

### Deploy Jenkins and Nginx to the local cluster
```bash
kubectl apply -f k8s/jenkins/
kubectl apply -f k8s/nginx/
```

### Run the full hybrid demo
The `start-demo.sh` script automates the entire flow: starting local
Kubernetes services, deploying local manifests, applying Terraform,
connecting to GKE, deploying and scaling a demo Nginx app, and printing
a final status summary (nodes, endpoints, external IP).

```bash
bash scripts/start-demo.sh
```

### Other scripts

| Script | Purpose |
|---|---|
| `check-cluster.sh` | Verify cluster health/connectivity |
| `deploy.sh` | Deploy application manifests |
| `verify.sh` | Verify deployment status |
| `cleanup.sh` | Tear down deployed resources |
| `demo.sh` | Run a shorter demo flow |

## Cleanup

```bash
bash scripts/cleanup.sh
cd terraform
terraform destroy
```

## Notes

- `terraform.tfvars` (real values) and any Terraform state/output files are
  intentionally excluded from version control — see `.gitignore`. Use
  `terraform.tfvars.example` as a template.
- The Jenkins ingress in the local cluster is configured for a `nip.io`
  hostname for local demo access.

## Author

Q. Allen - https://github.com/sql-qa/

## License

For academic purposes only.
