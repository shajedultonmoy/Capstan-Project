# Deployment Decision Note

## Overview

This document explains the engineering decisions made for the Capstan Project's CI/CD, containerization, and GitOps delivery pipeline.

## 1. Branching Strategy

### Three-Branch Model: `dev` → `stage` → `prod`

- **`main`**: Development branch where feature work happens. All PRs from feature branches target `main`.
- **`dev`**: Integration branch. Code from `main` is merged here for validation. Deployment to dev environment requires manual trigger.
- **`stage`**: Pre-production validation. Code from `dev` is promoted here. Deployment to staging requires manual trigger.
- **`prod`**: Production releases. Code from `stage` is merged here. Deployment is automatic when PRs are closed.

### Promotion Path

```
Feature Branch → main → dev → stage → prod
```

Each promotion is a separate merge, ensuring clear audit trails and explicit human decisions at each stage.

## 2. CI/CD Pipelines

### CI Pipeline (`ci.yml`)
- **Trigger**: Push to any branch, PRs to any branch
- **Steps**: Lint, typecheck, build for both frontend and backend
- **Docker Build**: Builds both images with commit SHA tags for traceability

### CD - Dev (`cd-dev.yml`)
- **Trigger**: `workflow_dispatch` (manual)
- **Why Manual**: Development environment is for testing new integrations. Manual triggers prevent accidental deployments of broken code.

### CD - Stage (`cd-stage.yml`)
- **Trigger**: `workflow_dispatch` (manual)
- **Why Manual**: Staging mirrors production. Manual triggers ensure a human has verified the changes in dev before promoting.

### CD - Prod (`cd-prod.yml`)
- **Trigger**: Pull request closed (merged) to `prod`
- **Why Auto**: Production deployments should be a consequence of code review and merge, not a separate manual step. This ensures all changes go through PR review before deployment.

## 3. Docker Images

### Dev Image (`Dockerfile.dev`)
- **Base**: `node:20-alpine`
- **Includes**: Debug tools (curl, wget, net-tools)
- **Purpose**: Development and debugging
- **Hot Reload**: Uses `tsx watch` for live reload

### Prod Image (`Dockerfile`)
- **Multi-stage Build**: Build stage + Production stage
- **Base**: `node:20-alpine` (production stage)
- **Optimizations**: 
  - `npm ci --omit=dev` for production dependencies only
  - `npm cache clean --force` to reduce image size
  - Non-root user for security
  - Health checks built-in

### Versioning Scheme
- **Format**: `{environment}-{commit_sha}`
- **Example**: `dev-abc1234`, `prod-xyz5678`
- **Why**: Provides traceability to exact source code while maintaining environment context

## 4. Kubernetes Manifests

### Environment Differentiation
- **Dev**: 1 replica, lower resource limits
- **Stage**: 2 replicas, moderate resources
- **Prod**: 3 replicas, higher resources

### Health Checks
- **Liveness**: Ensures container is running
- **Readiness**: Ensures container is ready to serve traffic

### Resource Limits
- Prevents runaway processes from affecting other workloads
- Ensures predictable performance

## 5. Argo CD (GitOps)

### Application per Environment
- Each environment has its own Argo CD Application
- Points to the corresponding branch in Git
- Auto-sync enabled with self-healing

### Benefits
- **Declarative**: Desired state in Git
- **Auditable**: All changes tracked in Git history
- **Self-healing**: Argo CD automatically corrects drift
- **Rollback**: Easy rollback by reverting Git commits

## 6. Security Considerations

- **Non-root containers**: Both backend and frontend run as non-root users
- **Health checks**: Built into Docker and Kubernetes manifests
- **Resource limits**: Prevents resource exhaustion
- **Secrets**: Environment-specific configuration via Kubernetes ConfigMaps/Secrets (not implemented in this demo but recommended)

## 7. Future Improvements

1. **Secrets Management**: Implement sealed-secrets or external-secrets for sensitive configuration
2. **Monitoring**: Add Prometheus/Grafana for metrics
3. **Logging**: Implement centralized logging with ELK stack
4. **Canary Deployments**: Consider progressive delivery for production
5. **Backup Strategy**: Implement etcd backups for disaster recovery
