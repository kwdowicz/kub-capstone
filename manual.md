# Milestone 11 implementation manual

This is the verified build record for the Kubernetes platform capstone. It is
written from the commands and runtime evidence produced during implementation,
not as a hypothetical tutorial.

Status: in progress

## 1. Outcome and ownership

The capstone builds a disposable local Kubernetes platform with three intended
reconcilers and no overlapping ownership:

| Layer | Owner |
| --- | --- |
| Kind cluster lifecycle and minimum Argo CD bootstrap | Terraform |
| Kubernetes platform components and workloads | Argo CD from Git |
| Grafana API objects | Separate Grafana Terraform root/repository |

The application source remains in `C:\Users\kwdow\dev\zeroapp`. This repository
owns cluster, bootstrap, GitOps, platform configuration, runbooks, and evidence.

## 2. Starting state

Verified on 2026-07-29:

- Windows 11 Pro build 26200, 16 GiB host memory.
- Docker Desktop 4.73.1 / Engine 29.4.3, 12 CPUs, approximately 7.7 GiB
  available to its Linux VM, cgroup v2.
- Approximately 305 GB free on `C:`.
- No Minikube or Kind cluster, active Kubernetes context, or leftover cluster
  container.
- Host Ethernet address `10.0.1.74/24`, gateway `10.0.1.1`.
- Ports 80 and 443 had no listener.
- All Windows Firewall profiles were enabled.
- GitHub CLI was installed but not authenticated. No external repository was
  created during the local bootstrap.

Tool versions:

| Tool | Version |
| --- | --- |
| Git | 2.54.0.1 |
| Terraform | 1.15.7 |
| Docker | 29.4.3 |
| kubectl | 1.34.1 |
| Kustomize embedded in kubectl | 5.7.1 |
| Helm | 4.2.3 |
| Kind CLI | 0.31.0 |
| Minikube reference installation | 1.38.1 |
| curl | 8.21.0 |

No Terraform semantic MCP/LSP integration or local `terraform-ls` adapter was
available. Terraform's native formatter, validator, provider schema, signed
lock checksums, saved plans, and runtime tests were used instead.

## 3. Local cluster architecture

ADR-001 selected community provider `tehcyx/kind` v0.11.0. It embeds the Kind
v0.31 generation and supports create/delete but not in-place cluster updates.
The cluster therefore has a deliberately disposable lifecycle.

The node image is pinned by digest:

```text
kindest/node:v1.35.0@sha256:452d707d4862f52530247495d180205e029056831160e22870e37e3f6c1ac31f
```

One control-plane node is used. Multiple Docker containers would not provide
real host-level availability and would consume memory needed by observability.

Kind's built-in network-policy implementation is retained. Enforcement must be
proved with allow and deny traffic before it is trusted.

The Kubernetes API remains loopback-only. Future LAN ingress follows this path:

```text
LAN 10.0.1.0/24 -> Windows 10.0.1.74:80/443
  -> Kind node 30080/30443
  -> Traefik NodePort Service
  -> application Service and Pod
```

## 4. Repository bootstrap

The repository was initialized locally on branch `main`. It had no remote.
`.gitignore` excludes Terraform caches, state, saved plans, project-local
kubeconfig, variable files, environment files, and private-key material. The
provider lock file is intentionally versioned.

The initial Terraform root is `terraform/cluster`:

- `versions.tf` constrains Terraform to the 1.15 patch line and pins
  `tehcyx/kind` to v0.11.0.
- `variables.tf` validates a DNS-compatible cluster name and requires the node
  image to include a semantic version plus SHA-256 digest.
- `main.tf` declares one Kind control-plane node, waits for readiness, writes an
  ignored project-local kubeconfig, and reserves host 80/443 to node
  30080/30443 mappings.
- `outputs.tf` exposes only non-secret connection metadata. Provider state still
  contains client credentials and must be treated as sensitive.
- `scripts/check.ps1` runs formatting, Terraform validation, and Git whitespace
  checks.

Commands used:

```powershell
terraform -chdir=terraform/cluster init
terraform -chdir=terraform/cluster providers
terraform -chdir=terraform/cluster validate
& .\scripts\check.ps1
terraform -chdir=terraform/cluster plan "-out=cluster-create.tfplan"
```

Observed results:

- `tehcyx/kind` v0.11.0 installed with developer signature key
  `F471C773A530ED1B`.
- `.terraform.lock.hcl` contains the selected version and registry checksums.
- Configuration validation succeeded.
- No state or kubeconfig existed after initialization and planning.
- The saved plan contained exactly `kind_cluster.platform: create` and no other
  action.

## 5. Cluster provisioning

Pending at the time this section was created. The saved plan must be inspected
and applied exactly, followed by Docker, Kubernetes, storage, DNS, API exposure,
port-binding, NetworkPolicy, and no-change-plan verification.
