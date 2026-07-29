locals {
  resolved_kubeconfig_path = abspath("${path.module}/${var.kubeconfig_path}")
}

provider "kubernetes" {
  config_path    = local.resolved_kubeconfig_path
  config_context = var.kube_context
}

provider "helm" {
  kubernetes = {
    config_path    = local.resolved_kubeconfig_path
    config_context = var.kube_context
  }
}

resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"

    labels = {
      "app.kubernetes.io/part-of"                  = "argocd"
      "app.kubernetes.io/managed-by"               = "Terraform"
      "pod-security.kubernetes.io/enforce"         = "baseline"
      "pod-security.kubernetes.io/enforce-version" = "latest"
      "pod-security.kubernetes.io/audit"           = "restricted"
      "pod-security.kubernetes.io/audit-version"   = "latest"
      "pod-security.kubernetes.io/warn"            = "restricted"
      "pod-security.kubernetes.io/warn-version"    = "latest"
    }
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "10.1.3"

  atomic          = true
  cleanup_on_fail = true
  lint            = true
  max_history     = 5
  timeout         = 900
  wait            = true
  wait_for_jobs   = true

  values = [
    file("${path.module}/argocd-values.yaml")
  ]
}

resource "helm_release" "gitops_entrypoint" {
  name      = "capstone-gitops-bootstrap"
  namespace = kubernetes_namespace_v1.argocd.metadata[0].name
  chart     = "${path.module}/charts/gitops-bootstrap"

  atomic          = true
  cleanup_on_fail = true
  max_history     = 5
  timeout         = 300
  wait            = true

  values = [
    yamlencode({
      repositoryUrl = var.gitops_repository_url
      revision      = var.gitops_revision
    })
  ]

  depends_on = [helm_release.argocd]
}
