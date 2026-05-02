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
          │
          ├── kargo-shared Application
          │     └── syncs kargo-shared/ → shared ClusterPromotionTasks available to all projects
          │
          └── cluster-addons Application
                └── syncs addons/ → creates per-addon ApplicationSets:
                      ├── addon-argo-rollouts → deploys to every cluster labeled fleet=true
                      └── addon-prometheus    → deploys to every cluster labeled fleet=true
```

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
│   └── <app>/
│       ├── argocd/           # AppProject + ApplicationSet
│       └── kargo/            # Project, Warehouse, Stages, Tasks
├── addons/                   # cluster add-ons, deploy to every fleet=true cluster
│   ├── argo-rollouts/        # ApplicationSet — progressive delivery controller
│   └── prometheus/           # ApplicationSet — metrics for rollout analysis
├── kargo-shared/             # shared ClusterPromotionTask resources
└── templated-teams/          # golden path: platform-owned rollout/ingress, teams supply image
```

## Adding a new app

1. Create `apps/<name>/argocd/` with an `AppProject` and `ApplicationSet`
2. Create `apps/<name>/kargo/` with `Project`, `Warehouse`, `Stage`, and `PromotionTask`
3. Push to your platform repo — ArgoCD auto-discovers via the `argocd-apps` and `kargo-apps` ApplicationSets

## Adding an addon to the fleet

1. Create `addons/<addon-name>/appset.yaml` — ApplicationSet using `clusters: {selector: {fleet: "true"}}`
2. The `cluster-addons` Application will pick it up on next sync

## Templated teams (golden path)

`templated-teams/` provides a Helm-templated standard project that platform controls. App teams supply:
- A Docker image + tag
- A few values in `platform/app-values.yaml` in their app repo

The `templated-teams/appset.yaml` discovers repos in the `dhpup` GitHub org that match `e2e-app-*` pattern, and the `appset-repos.yaml` discovers repos based on SCM provider.

## TODO before first use

All files containing `dhpup` need to be updated with your actual GitHub org/repo URLs:

```bash
grep -r "dhpup" . --include="*.yaml" -l
```
