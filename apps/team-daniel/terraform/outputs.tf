output "redis_url" {
  description = "Redis connection URL — injected into the guestbook app by Kargo"
  value       = "redis://${kubernetes_service.redis.metadata[0].name}.${kubernetes_namespace.backend.metadata[0].name}.svc.cluster.local:6379"
}

output "backend_namespace" {
  description = "Kubernetes namespace where the backend was provisioned"
  value       = kubernetes_namespace.backend.metadata[0].name
}

output "redis_host" {
  description = "Redis hostname (cluster-local DNS)"
  value       = "${kubernetes_service.redis.metadata[0].name}.${kubernetes_namespace.backend.metadata[0].name}.svc.cluster.local"
}

output "redis_port" {
  description = "Redis service port"
  value       = 6379
}

output "redis_image" {
  description = "Redis container image"
  value       = kubernetes_deployment.redis.spec[0].template[0].spec[0].container[0].image
}
