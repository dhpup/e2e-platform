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

# Explicit in-cluster auth — reads the service account token and CA cert
# that Kubernetes mounts into every pod automatically.
provider "kubernetes" {
  host                   = "https://kubernetes.default.svc"
  cluster_ca_certificate = file("/var/run/secrets/kubernetes.io/serviceaccount/ca.crt")
  token                  = file("/var/run/secrets/kubernetes.io/serviceaccount/token")
}
