variable "cluster_name" {
  description = "Name of the disposable local Kind cluster."
  type        = string
  default     = "platform-capstone"

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.cluster_name))
    error_message = "cluster_name must be a lowercase DNS-compatible name."
  }
}

variable "node_image" {
  description = "Digest-pinned Kind node image compatible with provider v0.11.0."
  type        = string
  default     = "kindest/node:v1.35.0@sha256:452d707d4862f52530247495d180205e029056831160e22870e37e3f6c1ac31f"

  validation {
    condition = can(regex(
      "^kindest/node:v[0-9]+\\.[0-9]+\\.[0-9]+@sha256:[0-9a-f]{64}$",
      var.node_image,
    ))
    error_message = "node_image must use a semantic version and sha256 digest."
  }
}
