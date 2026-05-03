# e2e-platform

Platform config repo for the local GitOps demo. Manages ArgoCD applications, Kargo pipelines, cluster addons, and shared promotion steps.

**Prerequisite:** Infrastructure must be bootstrapped first — see [e2e-infra](../e2e-infra/README.md).

## How everything wires together

```
make bootstrap-apps (one-time, from e2e-infra/)
    └── applies app-of-apps.yaml to ArgoCD

app-of-apps
    └── syncs bootstrap/ → creates:
          ├── argocd-apps ApplicationSet
          │     └── discovers apps/*/argocd/ → one ArgoCD Application per demo app
          │           each app's argocd/ contains AppProject + inner ApplicationSet
          │           which deploys app manifests to the target cluster(s)
          │
          ├── kargo-apps ApplicationSet
          │     └── discovers apps/*/kargo/ → syncs Kargo resources to the kargo cluster
          │           (auto-sync + prune enabled — pipeline changes apply immediately)
          │
          ├── kargo-shared Application
          │     └── syncs kargo-shared/ → shared ClusterPromotionTasks available to all projects
          │
          └── cluster-addons Application
                └── syncs addons/ → creates per-addon ApplicationSets:
                      ├── addon-argo-rollouts → deploys to every cluster labeled fleet=true
                      └── addon-prometheus    → deploys to every cluster labeled fleet=true
                      (auto-sync disabled — apps generate per cluster but don't deploy automatically)
```

## team-daniel pipeline

The `apps/team-daniel/` app is the primary demo app. Its Kargo pipeline:

```
Warehouse: team-daniel
  └── subscribes to: ghcr.io/akuity/guestbook (SemVer)
                     apps/team-daniel/base/feature-flags.yaml (git)
  │   (image + feature flags promoted as a unit)
  │
  ├── pipeline-refresh  [auto]  refreshes kargo-team-daniel in ArgoCD when
  │                             stages.yaml or project.yaml changes — new stages
  │                             appear in the Kargo UI within ~30s of a push
  │
  ├── dev               [auto]  provision-backend (Terraform → Redis in k3d, PR gate)
  │                             + promote-guestbook (image tag + feature flags)
  │
  └── prod-demo1        [manual]  same tasks, targets the demo1 fleet cluster
      prod-demo2        [manual]  added automatically by make register-cluster
```

**Per-stage Terraform state** — each stage stores its own `terraform.tfstate` at
`env/$stage/terraform.tfstate` (committed to git). A per-stage `env/$stage/backend.tf`
configures the local backend path; the `provision-backend` task copies it into the
shared `terraform/` directory before applying, then removes it after.

## Directory structure

```
e2e-platform/
├── app-of-apps.yaml          # one-time bootstrap — apply this once to seed everything
├── bootstrap/                # ApplicationSets + Applications created by app-of-apps
│   ├── argocd-apps.yaml      # discovers apps/*/argocd/
│   ├── kargo-apps.yaml       # discovers apps/*/kargo/
│   ├── kargo-shared.yaml     # shared ClusterPromotionSteps
│   └── cluster-addons.yaml   # bootstraps the addons layer
├── apps/                     # one directory per demo app
│   └── team-daniel/
│       ├── argocd/           # AppProject + ApplicationSets (dev + prod fleet)
│       ├── kargo/            # Project, Warehouse, Stages, Tasks, pipeline-refresh
│       ├── charts/           # Helm chart for the guestbook app
│       ├── env/              # per-stage values (image.yaml, config.yaml,
│       │                     #   feature-flags.yaml, backend.tf, terraform.tfstate)
│       ├── base/             # shared base config (feature-flags.yaml)
│       ├── terraform/        # shared OpenTofu module (no state stored here)
│       └── rbac/             # Kargo agent RBAC for Terraform
├── addons/                   # cluster add-ons, one ApplicationSet per addon
│   ├── argo-rollouts/
│   └── prometheus/
├── kargo-shared/             # shared ClusterPromotionTask resources
└── templated-teams/          # golden path: platform-owned rollout/ingress
```

## Adding a new app

1. Create `apps/<name>/argocd/` with an `AppProject` and `ApplicationSet`
2. Create `apps/<name>/kargo/` with `Project`, `Warehouse`, `Stage`, and `PromotionTask`
3. Push — ArgoCD auto-discovers via the `argocd-apps` and `kargo-apps` ApplicationSets

## Adding an addon to the fleet

1. Create `addons/<addon-name>/appset.yaml` — ApplicationSet using `clusters: {selector: {fleet: "true"}}`
2. The `cluster-addons` Application will pick it up on next sync

## TODO before first use

Update all `dhpup` references with your actual GitHub org/repo URLs:

```bash
grep -r "dhpup" . --include="*.yaml" -l
```
