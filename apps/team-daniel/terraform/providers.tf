terraform {
  required_version = ">= 1.5"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }
  }

  # State is committed to git alongside the Terraform config.
  # For production, replace this with a remote backend (S3, GCS, k8s secret, etc.)
  backend "local" {}
}

# When this runs inside the Kargo agent pod in k3d, the provider automatically
# picks up the in-cluster service account token — no explicit config needed.
provider "kubernetes" {}
