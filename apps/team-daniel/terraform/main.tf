locals {
  # Each stage gets its own isolated namespace so dev/staging/prod don't share state
  namespace = "${var.app}-backend-${var.stage}"
  labels = {
    "app"                          = "redis"
    "app.kubernetes.io/managed-by" = "terraform"
    "app.kubernetes.io/part-of"    = var.app
    "kargo.akuity.io/stage"        = var.stage
  }
}

resource "kubernetes_namespace" "backend" {
  metadata {
    name   = local.namespace
    labels = { "app.kubernetes.io/managed-by" = "terraform" }
  }
}

resource "kubernetes_deployment" "redis" {
  metadata {
    name      = "redis"
    namespace = kubernetes_namespace.backend.metadata[0].name
    labels    = local.labels
  }
  spec {
    replicas = 1
    selector { match_labels = { app = "redis" } }
    template {
      metadata { labels = local.labels }
      spec {
        container {
          name              = "redis"
          image             = "redis:7-alpine"
          image_pull_policy = "IfNotPresent"
          port { container_port = 6379 }
          resources {
            requests = { cpu = "10m", memory = "32Mi" }
            limits   = { memory = "64Mi" }
          }
        }
      }
    }
  }
  # Ignore changes to the image so Terraform doesn't fight with k8s rollouts
  lifecycle {
    ignore_changes = [spec[0].template[0].spec[0].container[0].image]
  }
}

resource "kubernetes_service" "redis" {
  metadata {
    name      = "redis"
    namespace = kubernetes_namespace.backend.metadata[0].name
    labels    = local.labels
  }
  spec {
    selector = { app = "redis" }
    port {
      name        = "redis"
      port        = 6379
      target_port = 6379
    }
  }
}
