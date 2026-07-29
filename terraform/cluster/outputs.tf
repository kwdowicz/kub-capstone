output "cluster_name" {
  description = "Terraform-owned Kind cluster name."
  value       = kind_cluster.platform.name
}

output "context_name" {
  description = "kubectl context written to the project-local kubeconfig."
  value       = "kind-${kind_cluster.platform.name}"
}

output "kubeconfig_path" {
  description = "Ignored project-local kubeconfig path."
  value       = kind_cluster.platform.kubeconfig_path
}

output "api_endpoint" {
  description = "Loopback Kubernetes API endpoint."
  value       = kind_cluster.platform.endpoint
}
