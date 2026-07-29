output "argocd_chart" {
  description = "Pinned Argo CD Helm chart version."
  value       = helm_release.argocd.version
}

output "argocd_namespace" {
  description = "Namespace owned by bootstrap Terraform."
  value       = kubernetes_namespace_v1.argocd.metadata[0].name
}

output "root_application" {
  description = "Terraform-owned Argo CD entrypoint; all child desired state is owned by Argo CD."
  value       = "capstone-root"
}

output "bootstrap_releases" {
  description = "Helm releases retained by bootstrap Terraform."
  value       = [helm_release.argocd.name, helm_release.gitops_entrypoint.name]
}
