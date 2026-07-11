# Weekend CI/CD: GitHub Actions + FluxCD + Istio on AWS EKS

End-to-end GitOps pipeline:

- **CI** — GitHub Actions builds/tests the Go demo app and pushes images to GHCR. CI never touches the cluster.
- **CD** — FluxCD pulls this repo, reconciles the cluster, and its image automation commits new image tags back to git.
- **Mesh / ingress** — Istio (sidecar mode) with strict mTLS; traffic enters through a Kubernetes Gateway API `Gateway` (Istio-provisioned AWS NLB) and `HTTPRoute`s. No nginx, no classic Ingress.

```
 dev pushes code                        Flux commits tag bumps back
       │                                          ▲
       ▼                                          │
┌──────────────┐   builds/pushes   ┌──────┐       │
│ GitHub repo  │──GitHub Actions──▶│ GHCR │       │
│  (monorepo)  │                   └──┬───┘       │
└──────┬───────┘                      │ scans new tags
       │ Flux pulls manifests         ▼
       │        ┌────────────────────────────────────────────┐
       └───────▶│ EKS cluster (Flux + istiod)                │
                │                                            │
 users ──▶ NLB ─┼─▶ Istio Gateway (Gateway API)              │
                │      ├─ HTTPRoute ─▶ staging ns    (mTLS)  │
                │      └─ HTTPRoute ─▶ production ns (mTLS)  │
                └────────────────────────────────────────────┘
```

## Layout

| Path | What |
|---|---|
| `apps/demo-app/` | Go HTTP service + Dockerfile |
| `terraform/` | VPC + EKS 1.35 (2× t3.medium **spot**, public subnets, **no NAT**) |
| `clusters/dev/` | Flux entry point: Kustomization chain + image automation |
| `kubernetes/infrastructure/` | Gateway API CRDs → Istio HelmReleases → Gateway + STRICT mTLS |
| `kubernetes/apps/` | demo-app base + `staging` / `production` overlays |
| `.github/workflows/` | `ci.yaml` (main builds), `release.yaml` (semver tags), `validate.yaml` (PR gates) |

Reconciliation order (Flux `dependsOn`): `infra-crds → infra-controllers → infra-configs → apps-staging / apps-production`.

## Runbook

### 0. Prerequisites (one-time)

```bash
# working AWS credentials (currently expired on this machine!)
aws sts get-caller-identity

# flux CLI
curl -s https://fluxcd.io/install.sh | sudo bash

# GitHub PAT with repo scope, for flux bootstrap
export GITHUB_TOKEN=<pat>
export GITHUB_USER=HaRsH020772
```

Create the GitHub repo (public keeps GHCR pulls anonymous) and push this code to `main`.

### 1. First CI run

Pushing to `main` triggers `ci.yaml` → image lands at `ghcr.io/harsh020772/demo-app`.
**Once, after the first push:** GitHub → Packages → `demo-app` → Package settings → Change visibility → **Public** (so the cluster can pull without imagePullSecrets).

### 2. Cluster

```bash
cd terraform
terraform init
terraform apply            # ~15 min
aws eks update-kubeconfig --region us-east-1 --name weekend-eks
kubectl get nodes          # 2 Ready spot nodes
```

### 3. Flux bootstrap

```bash
flux bootstrap github \
  --owner "$GITHUB_USER" \
  --repository weekend-11.07.2026 \
  --branch main \
  --path clusters/dev \
  --personal \
  --components-extra image-reflector-controller,image-automation-controller
```

Then watch it converge:

```bash
flux get kustomizations --watch     # crds → controllers → configs → apps, all Ready
kubectl get gateway -n istio-ingress  # ADDRESS = NLB DNS once Programmed (~2 min)
```

Note: pods may show `ImagePullBackOff` until the first CI image exists and image
automation commits the real tag — it self-heals within a few minutes.

### 4. Traffic test (no DNS needed)

```bash
NLB=$(kubectl get gateway public-gateway -n istio-ingress \
  -o jsonpath='{.status.addresses[0].value}')
curl -H "Host: staging.demo.local" "http://$NLB/"
curl -H "Host: demo.local"        "http://$NLB/"
```

### 5. The full CD loop

1. Edit the message in `apps/demo-app/main.go`, push to `main`.
2. Actions builds `main-<sha>-<timestamp>` → Flux's `ImagePolicy` picks it up →
   `fluxcdbot` commits the tag bump (check `git pull && git log`) → staging redeploys.
3. **Promote to production**: `git tag v1.0.0 && git push --tags` →
   `release.yaml` publishes `1.0.0` → the semver `ImagePolicy` rolls production.
4. Rollback = `git revert` the bot commit (staging) or point the semver range at
   the previous release (production).

### 6. Teardown (do this before Monday!)

```bash
# delete the Gateway first — its NLB was created by Istio, not Terraform
kubectl delete gateway public-gateway -n istio-ingress
cd terraform && terraform destroy
# sanity: no leftover load balancers / volumes
aws elbv2 describe-load-balancers --region us-east-1
aws ec2 describe-volumes --region us-east-1 --filters Name=status,Values=available
```

Rebuild any time: `terraform apply` + `flux bootstrap` — everything else is in git.

## Cost (us-east-1)

| Item | Rate | 48 h weekend |
|---|---|---|
| EKS control plane | $0.10/hr | ~$4.80 |
| 2× t3.medium spot | ~$0.013/hr each | ~$1.25 |
| NLB (Istio Gateway) | ~$0.0225/hr + LCU | ~$1.20 |
| EBS 2× 20 GB gp3 | — | ~$0.10 |
| **Total** | | **~$7–8** |

Left running it's ~$110/month — always destroy.

## Flux features demonstrated

- **GitRepository + Kustomization sync** with `prune`, `wait`/health checks, and a `dependsOn` chain (CRDs → Istio → mesh config → apps)
- **HelmRelease + helm-controller** (Istio install, pinned `1.30.x`, CRD upgrades handled)
- **Image automation** (ImageRepository / ImagePolicy / ImageUpdateAutomation): timestamp-sorted tags for staging, semver for production, bot commits back to git
- **Kustomize overlays** for staging/production on one cluster

### Next steps / stretch

- **notification-controller**: `Alert` + `Provider` → Discord/Slack webhook + GitHub commit statuses
- **SOPS + age**: encrypted Secrets in git, decrypted by kustomize-controller
- **Webhook Receiver**: GitHub push webhook → instant reconcile, exposed via its own `HTTPRoute` on the existing Gateway
- **Flagger** (Gateway API provider): automated canary — shifts HTTPRoute weights while watching metrics, auto-rollback
- **kube-prometheus-stack** HelmRelease + Flux Grafana dashboards; **Kiali** for mesh topology
- **Istio ambient mode** instead of sidecars; **Trivy** scan step in CI; **Renovate**
