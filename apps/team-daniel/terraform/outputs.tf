output "redis_url" {
  description = "Redis connection URL — injected into the guestbook app by Kargo"
  value       = "redis://${kubernetes_service.redis.metadata[0].name}.${kubernetes_namespace.backend.metadata[0].name}.svc.cluster.local:6379"
}

output "backend_namespace" {
  description = "Kubernetes namespace where the backend was provisioned"
  value       = kubernetes_namespace.backend.metadata[0].name
}
