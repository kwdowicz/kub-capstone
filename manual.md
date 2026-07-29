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
- GitHub CLI was initially unauthenticated. After the operator authenticated it,
  the reviewed baseline was published as the public repository
  `https://github.com/kwdowicz/kub-capstone`.

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

The inspected saved plan was applied from its own Terraform root:

```powershell
terraform -chdir=terraform/cluster apply cluster-create.tfplan
$env:KUBECONFIG = (Resolve-Path .\.local\kubeconfig)
kubectl get nodes -o wide
kubectl get pods -A -o wide
kubectl get storageclass
kubectl get --raw='/readyz?verbose'
terraform -chdir=terraform/cluster plan -detailed-exitcode -no-color
```

Observed results:

- Terraform reported `1 added, 0 changed, 0 destroyed`.
- Cluster `platform-capstone` and context `kind-platform-capstone` were created.
- The control-plane node became `Ready` on Kubernetes v1.35.0.
- API server, etcd, scheduler, controller-manager, CoreDNS, kube-proxy, Kindnet,
  and the local-path provisioner were running.
- StorageClass `standard` used `WaitForFirstConsumer` and reclaim policy
  `Delete`; it is convenient local storage, not a high-availability design.
- Every API `/readyz` check passed.
- The Docker node used the expected pinned image digest. Its node/container IP
  was `172.18.0.2`; Services and Pods use separate cluster address spaces.
- Docker exposed API port 6443 only through random loopback port 62092. Host
  `0.0.0.0:80` and `0.0.0.0:443` map to node ports 30080 and 30443. The Windows
  LAN address remains `10.0.1.74`; those four address types are not
  interchangeable.
- A second Terraform plan returned exit code 0 and `No changes`.

State and `.local/kubeconfig` remain ignored local credentials. Destroying this
root deletes the exact Kind cluster; broad Docker cleanup is never required.

## 6. NetworkPolicy behavior proof

`tests/network-policy` creates a temporary namespace, an unprivileged nginx
server and probe, and two policies. `scripts/test-network-policy.ps1` verifies
three states: baseline traffic succeeds, selected ingress is denied, then a
label-scoped allow restores it. It always deletes the namespace in `finally`.

```powershell
& .\scripts\test-network-policy.ps1
```

Final evidence was `NetworkPolicyTest=PASS`. The first attempt also documented
two useful harness failures: a separate multi-platform curl image was slow to
pull and failed Kind's containerd import, and Windows PowerShell elevated the
expected denied probe's stderr into a terminating error. The durable test now
reuses the already-pulled nginx Alpine image for `wget` and locally relaxes
PowerShell error handling only around the connection that is expected to fail.
These were test-harness corrections; the observed deny timeout confirmed that
Kindnet enforcement was active.

## 7. Git publication

After explicit GitHub authorization, the secret scan was clean and the public
repository was created and pushed:

```powershell
gh repo create kwdowicz/kub-capstone --public --source . --remote origin --push
git remote -v
```

The repository is public specifically so Argo CD can clone desired state
read-only without a repository credential. No Terraform state, saved plan,
kubeconfig, token, private key, or environment secret was published.

## 8. Argo CD bootstrap and first reconciliation

Current primary sources were checked before pinning. Bootstrap uses official
HashiCorp Helm provider 3.2.0, Kubernetes provider 3.2.1, and Argo CD chart
10.1.3 (application v3.4.5). Terraform state is isolated under
`terraform/bootstrap`.

Terraform permanently owns exactly these objects:

- Namespace `argocd`;
- Helm release `argocd`, including CRDs and the resource-conscious non-HA
  runtime;
- Helm release `capstone-gitops-bootstrap`, containing only AppProject
  `capstone-bootstrap` and Application `capstone-root`.

The root Application owns `gitops/root`, beginning with AppProject
`capstone-platform`. All later platform components and workloads descend from
that Git boundary and are never added to Terraform state.

The first apply failed safely because putting `Application` objects in the main
chart's `extraObjects` made the Helm provider validate them before their CRDs
existed. Atomic cleanup removed that release and left only the already-created
namespace in state. The correction split the two custom resources into a tiny
local Helm chart with an explicit dependency on the Argo CD release.

```powershell
terraform -chdir=terraform/bootstrap init
terraform -chdir=terraform/bootstrap validate
helm lint .\terraform\bootstrap\charts\gitops-bootstrap
terraform -chdir=terraform/bootstrap plan "-out=argocd-bootstrap-v2.tfplan"
terraform -chdir=terraform/bootstrap apply argocd-bootstrap-v2.tfplan
```

The corrected apply added both releases. The application controller, Redis,
repo server, and API/UI server became Ready; Dex and notifications were
disabled and ApplicationSet was scaled to zero. Four component NetworkPolicies
and metric Services were created. An in-cluster `/healthz` probe returned `ok`.

The root Application intentionally started `OutOfSync/Missing`. A one-time
non-pruning operation was submitted from an ignored JSON patch file. It became
`Synced/Healthy` and created only `capstone-platform`. Automated sync, pruning,
and self-healing were then enabled by updating the Terraform-owned bootstrap
chart. A deliberately corrupted project description became `OutOfSync` and was
restored from Git: `ArgoSelfHeal=PASS`.

Argo CD CLI 3.4.5 was installed from Winget and `argocd app get --core` showed
the root app Synced and Healthy. A temporary local port-forward returned HTTP
200 for the UI and `ok` for `/healthz`; it was stopped immediately. No admin
password was printed or written to this repository.

The no-change bootstrap plan returned exit code 0. Normal recovery order is:
create the cluster root, apply the bootstrap root, and let the public Git source
reconcile. Destruction is the reverse: deliberately remove/disable Argo-owned
children first, destroy `terraform/bootstrap`, then destroy
`terraform/cluster`. Deleting the cluster before bootstrap state is accepted
only as a disaster-recovery exercise and requires state reconciliation.
