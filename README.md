# PG-EKS-Gitops — Glodios Production Infrastructure

AWS infrastructure for the **Glodios** payment gateway -  A Pet Project. Terraform provisions the base infrastructure, ArgoCD manages everything in-cluster via GitOps.

## Stack

| Layer | Technology |
|---|---|
| Cloud | AWS (us-east-1) |
| IaC | Terraform |
| Cluster | EKS 1.31 |
| GitOps | ArgoCD (App-of-Apps) |
| App packaging | Helm |
| Database | RDS PostgreSQL 16 |
| Cache / Queue | Redis (StatefulSet) |
| Frontend CDN | CloudFront + S3 |
| Observability | Prometheus + Grafana + Loki |
| Secrets | AWS Secrets Manager + External Secrets Operator |

## Repo Layout

```
├── terraform/
│   ├── env/prod/          # Root module (VPC, EKS, IAM, RDS, CloudFront, Route53)
│   └── modules/           # eks | iam | rds | cloudfront | route53
└── EKS/
    ├── gitops/
    │   ├── bootstrap/     # ArgoCD install + root App-of-Apps
    │   ├── apps/          # backend, celery ArgoCD Applications
    │   └── infra/         # AWS LBC, External Secrets, Prometheus, Loki, Redis
    ├── helm/
    │   ├── backend/       # Django API chart
    │   ├── celery/        # Celery worker chart
    │   ├── redis/         # Redis StatefulSet chart
    │   └── obs/           # Prometheus & Loki value overrides
    └── K8s/               # RBAC, aws-auth
```

## Getting Started

**1. Provision infrastructure**
```bash
cd terraform/env/prod
terraform init && terraform apply
```

**2. Connect kubectl**
```bash
aws eks update-kubeconfig --region us-east-1 --name glodios-eks-cluster
```

**3. Bootstrap ArgoCD**
```bash
kubectl apply -f EKS/gitops/bootstrap/argocd-install.yaml
kubectl apply -f EKS/gitops/bootstrap/app-of-apps.yaml
```

ArgoCD takes it from here — infra controllers deploy first (sync wave `-2`, `-1`), then the backend and Celery apps (wave `1`).

## Node Groups

| Group | Type | Instance | Purpose |
|---|---|---|---|
| `app-ondemand` | On-Demand | t3.xlarge | Always-on app baseline |
| `app-spot` | Spot | t3.xlarge / m5.xlarge / m5.large | Burst capacity |
| `observability-nodes` | On-Demand | m5.large | Monitoring stack (tainted) |

## EKS Upgrade Path

```
1.31 → 1.32 → 1.33
```
One minor version at a time. Update `cluster_version` in `terraform/env/prod/main.tf`, then `terraform apply`.
