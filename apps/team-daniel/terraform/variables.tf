variable "stage" {
  description = "Kargo stage name (dev, staging, staging-security, prod-canary)"
  type        = string
}

variable "app" {
  description = "Application name — used to namespace Kubernetes resources"
  type        = string
  default     = "team-daniel"
}
