# ADR-001: Terraform-owned local Kind cluster

- Status: Accepted
- Date: 2026-07-29
- Decision owners: learner and platform capstone guide

## Context

The capstone must create and destroy a no-cost local Kubernetes cluster through
Terraform. It runs on Windows 11 with Docker Desktop and must later support
Argo CD, Traefik, PostgreSQL, observability, NetworkPolicy, LAN access, TLS, and
a complete destroy/rebuild exercise.

The host has 16 GiB physical memory. Docker Desktop currently exposes 12 CPUs
and approximately 7.7 GiB to its Linux VM. Host ports 80 and 443 are available.
The host uses Ethernet address `10.0.1.74` on subnet `10.0.1.0/24`, and all
Windows Firewall profiles are enabled.

Minikube is familiar from the previous labs but has no reliable official
Terraform lifecycle provider. Calling a cluster CLI from `local-exec` would
hide lifecycle, drift, update, and error semantics from Terraform.

## Decision

Use `tehcyx/kind` Terraform provider v0.11.0 to own a single-node Kind cluster.
The provider is community-maintained rather than an official HashiCorp or
Kubernetes SIG provider. Version 0.11.0 embeds Kind v0.31.0 and includes a fix
for a destroy-time kubeconfig write-back crash.

Use this node image and immutable digest from the Kind v0.31.0 release:

```text
kindest/node:v1.35.0@sha256:452d707d4862f52530247495d180205e029056831160e22870e37e3f6c1ac31f
```

The cluster will have one control-plane node. Additional container nodes would
share the same Docker Desktop VM and would not provide real host-level
availability, while consuming memory needed by the observability stack.

Keep the Kubernetes API server bound to loopback. Do not expose it to the LAN.

Retain Kind's default `kindnetd` networking. Kind has included out-of-the-box
Kubernetes NetworkPolicy support since v0.24.0. The capstone must still verify
actual default-deny, allowed, and denied flows before relying on it. Cilium or
Calico may be reconsidered only if the required policy behavior is missing or a
specific advanced networking lesson justifies their added complexity and cost.

Reserve this ingress path during cluster creation:

```text
LAN client
  -> Windows 10.0.1.74:80/443
  -> Docker Desktop Kind mappings
  -> control-plane container ports 30080/30443
  -> Traefik NodePort Service 30080/30443
  -> Traefik Pod
  -> application Service and Pod
```

The Kind node mappings will therefore be:

| Host bind | Host port | Node container port | Protocol |
| --- | ---: | ---: | --- |
| `0.0.0.0` | 80 | 30080 | TCP |
| `0.0.0.0` | 443 | 30443 | TCP |

Traefik is not part of cluster Terraform. Argo CD will later own its Helm
release and configure those fixed NodePorts. Until then, the mapped ports have
no backend listener.

LAN access will require narrowly scoped Windows Firewall inbound rules for the
Private profile and local subnet. Firewall state is external to Kubernetes and
Terraform until an explicit owner is selected, so creation and rollback
commands must be recorded in a runbook.

Terraform state and kubeconfig are sensitive local artifacts. They must remain
ignored and must never be committed. Provider and node-image versions will be
locked; the provider lock file will be committed.

## Consequences

### Benefits

- Terraform has a real create/destroy lifecycle for the local cluster.
- The cluster remains free, disposable, and compatible with Docker Desktop.
- Fixed port mappings make the Windows, Docker, node, Service, and Pod network
  boundaries visible and testable.
- Built-in NetworkPolicy support avoids an additional CNI control plane on a
  memory-constrained desktop.
- Digest pinning makes cluster rebuilds reproducible.

### Costs and risks

- The provider is community-owned and may lag Kind or Terraform releases.
- `kind_cluster` does not support in-place modification. Many configuration
  changes replace the cluster; data must therefore be backed up and restored.
- Provider v0.11.0 embeds Kind v0.31.0 while standalone Kind v0.32.0 is newer.
  We intentionally use the matching v0.31.0 node-image generation rather than
  mixing it with v0.32-only images and containerd behavior.
- A single node cannot demonstrate genuine host failure or control-plane HA.
- Binding ingress to `0.0.0.0` makes Windows Firewall scope and TLS mandatory
  before real application exposure.
- Kind is a development cluster and does not provide a production upgrade or
  security lifecycle. The Kubernetes API stays on loopback.

## Alternatives considered

### Minikube outside Terraform

Rejected for this capstone. It is operationally familiar but does not satisfy
the requirement that Terraform own cluster creation and destruction.

### CLI invocation through `local-exec`

Rejected. A provisioner would make a command run, but it would not provide a
reliable resource schema, lifecycle, drift model, or safe update semantics.

### Cilium or Calico from initial bootstrap

Deferred. Both can enforce network policy and teach additional networking
concepts, but Kind's built-in implementation covers the current requirement
with a smaller resource footprint. Revisit only with evidence.

### AKS, EKS, or GKE

Deferred. An official cloud provider would be more enterprise-faithful but
requires credentials, budget, quota, capacity, security, and cleanup authority
that are not granted for the local capstone.

## Replacement and recovery strategy

1. Keep all cluster and GitOps desired state in Git under explicit owners.
2. Back up PostgreSQL and record image digests before any replacement plan.
3. Inspect Terraform plans; treat replacement of `kind_cluster` as destructive.
4. Destroy in reverse ownership order when data protection requires it.
5. Recreate the cluster through Terraform, bootstrap Argo CD, reconcile from
   Git, restore data, and rerun behavior and telemetry checks.
6. If `tehcyx/kind` becomes unmaintained or incompatible, replace the cluster
   Terraform root behind the same kubeconfig/output contract. Do not make
   Argo-owned manifests depend on provider-specific details.

## Validation required before closing cluster provisioning

- Provider lock and checksum are committed.
- Saved Terraform plan contains only the expected cluster creation.
- Node image is pinned by digest.
- Docker confirms the exact node container and port bindings.
- Kubernetes node, DNS, storage, and system Pods are healthy.
- Kubernetes API is reachable only through loopback.
- NetworkPolicy is proven with both allowed and denied traffic.
- A second Terraform plan reports no changes.
- A reviewed destroy plan targets only this cluster.

## Primary sources checked

- Kind configuration and port mappings:
  https://kind.sigs.k8s.io/docs/user/configuration/
- Kind v0.31.0 release and node-image digests:
  https://github.com/kubernetes-sigs/kind/releases/tag/v0.31.0
- Kind v0.24.0 built-in NetworkPolicy support:
  https://github.com/kubernetes-sigs/kind/releases/tag/v0.24.0
- Terraform provider registry entry:
  https://registry.terraform.io/providers/tehcyx/kind/latest
- Terraform provider v0.11.0 release:
  https://github.com/tehcyx/terraform-provider-kind/releases/tag/v0.11.0
