variable "kubeconfig_path" {
  description = "Project-local kubeconfig produced by the cluster Terraform root."
  type        = string
  default     = "../../.local/kubeconfig"
}

variable "kube_context" {
  description = "Kind context that the bootstrap providers must use."
  type        = string
  default     = "kind-platform-capstone"
}

variable "gitops_repository_url" {
  description = "Public read-only Git repository reconciled by the root Argo CD application."
  type        = string
  default     = "https://github.com/kwdowicz/kub-capstone.git"

  validation {
    condition     = can(regex("^https://github\\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+\\.git$", var.gitops_repository_url))
    error_message = "gitops_repository_url must be an HTTPS GitHub clone URL ending in .git."
  }
}

variable "gitops_revision" {
  description = "Git revision reconciled by Argo CD."
  type        = string
  default     = "main"
}
