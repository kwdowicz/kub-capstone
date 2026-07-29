locals {
  # Keep cluster credentials out of the global kubeconfig and out of Git.
  kubeconfig_path = abspath("${path.root}/../../.local/kubeconfig")
}

resource "kind_cluster" "platform" {
  name            = var.cluster_name
  node_image      = var.node_image
  wait_for_ready  = true
  kubeconfig_path = local.kubeconfig_path

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"

      # Docker Desktop exposes these ports on all host interfaces by default.
      # Later, Argo CD will configure Traefik with matching fixed NodePorts.
      extra_port_mappings {
        host_port      = 80
        container_port = 30080
      }

      extra_port_mappings {
        host_port      = 443
        container_port = 30443
      }
    }
  }
}
