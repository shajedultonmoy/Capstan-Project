# Capstan Project - DevOps Practical Assignment

## Overview

This repository contains the Support Chat application with a complete CI/CD, containerization, and GitOps delivery pipeline deployed on AWS EC2.

**Server:** STCP  
**IP:** 34.238.235.55  
**VPC:** vpc-0410135730a485283

## Repository Structure

```
Capstan-Project/
├── .github/workflows/          # CI/CD pipelines
│   ├── ci.yml                  # CI: lint, typecheck, build
│   ├── cd-dev.yml              # CD: deploy to dev (manual)
│   ├── cd-stage.yml            # CD: deploy to stage (manual)
│   └── cd-prod.yml             # CD: deploy to prod (auto on PR)
├── k8s/                        # Kubernetes manifests
│   ├── dev/                    # Development environment
│   ├── stage/                  # Staging environment
│   └── prod/                   # Production environment
├── argocd/                     # Argo CD applications
├── scripts/                    # Server setup scripts
├── simpleChatserver/           # Backend (Express/Socket.IO)
├── simpleChatui/               # Frontend (React/Vite)
└── DECISIONS.md                # Engineering decisions
```

## Quick Start

### 1. Server Setup

SSH into your EC2 server and run:

```bash
# Clone the repository
git clone https://github.com/shajedultonmoy/Capstan-Project.git
cd Capstan-Project

# Run setup script
chmod +x scripts/setup-server.sh
./scripts/setup-server.sh
```

### 2. GitHub Actions Secrets

Add these secrets to your GitHub repository:

| Secret | Description |
|--------|-------------|
| `EC2_SSH_KEY` | Private SSH key for EC2 server |
| `GHCR_TOKEN` | GitHub Container Registry token |

### 3. AWS Security Group

Open these ports in your EC2 Security Group:

| Port | Purpose |
|------|---------|
| 22 | SSH access |
| 6443 | k3s API server |
| 30080 | Dev frontend |
| 30081 | Dev backend |
| 30082 | Stage frontend |
| 30083 | Stage backend |
| 30084 | Prod frontend |
| 30085 | Prod backend |

## Branching Strategy

```
main → dev → stage → prod
         ↓       ↓       ↓
      Manual  Manual  Auto (PR)
```

- **main**: Feature development
- **dev**: Integration testing (manual deployment)
- **stage**: Pre-production validation (manual deployment)
- **prod**: Production releases (automatic on PR merge)

## Environments

| Environment | Frontend | Backend | NodePort |
|-------------|----------|---------|----------|
| Dev | 30080 | 30081 | 30080-30081 |
| Stage | 30082 | 30083 | 30082-30083 |
| Prod | 30084 | 30085 | 30084-30085 |

## Access Points

- **Dev Frontend:** http://34.238.235.55:30080
- **Stage Frontend:** http://34.238.235.55:30082
- **Prod Frontend:** http://34.238.235.55:30084
- **Argo CD UI:** http://34.238.235.55:30080/argocd

## Argo CD

**Login:**
- Username: `admin`
- Password: Get from server with:
  ```bash
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
  ```

## Docker Images

Images are pushed to GitHub Container Registry (GHCR) with format:
- `ghcr.io/shajedultonmoy/chat-backend:{env}-{sha}`
- `ghcr.io/shajedultonmoy/chat-frontend:{env}-{sha}`

## CI/CD Workflows

1. **CI (ci.yml):** Runs on all pushes/PRs - lint, typecheck, build
2. **CD Dev (cd-dev.yml):** Manual trigger - build & deploy to dev
3. **CD Stage (cd-stage.yml):** Manual trigger - build & deploy to stage
4. **CD Prod (cd-prod.yml):** Auto-trigger on PR merge to prod

## Local Development

```bash
# Backend
cd simpleChatserver
npm install
npm run dev

# Frontend (new terminal)
cd simpleChatui
npm install
npm run dev
```

Open http://localhost:5173

## Documentation

- [Deployment Decisions](DECISIONS.md)
- [Server Setup Guide](scripts/setup-server.sh)

- Testing final pipeline deployment
