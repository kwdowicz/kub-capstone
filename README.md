# Kubernetes Platform Capstone

> Runtime status: stopped and fully torn down on 2026-07-29. Source and build
> history are retained; see `manual.md` section 9 for verified cleanup evidence.

This is the clean handoff for milestone 11 of the Kubernetes learning path.
The workspace intentionally starts with only this file. Do not copy the old
`kub` repository into this directory wholesale.

## Prompt for a new Codex chat

Use this prompt after opening `C:\Users\kwdow\dev\kub-capstone`:

> Read README.md completely and continue from the first incomplete checkpoint.
> Act as an interactive instructor. Give me coherent 5-15 minute checkpoints,
> let me run the meaningful commands, inspect my output, and explain ownership,
> rollback, security, and the enterprise analogue. Do not reduce every command
> to a separate exercise. Verify current tool/provider versions from primary
> sources before choosing or installing them.

## Working agreement

- Use Windows PowerShell commands that can be copied as written.
- Prefer outcome-sized checkpoints, normally several related commands followed
  by one review.
- Before each checkpoint, state its objective, owner, expected result, rollback,
  and whether it is destructive, externally visible, or potentially billable.
- The learner normally runs the commands. Codex may run them when explicitly
  delegated, especially for cleanup or diagnostics.
- Inspect real output before declaring success. Record the relevant evidence in
  this repository as the build progresses.
- Pause at meaningful architecture, security, external-publication, cost, and
  destructive gates. Do not pause after every harmless command.
- Make sensible bounded implementation choices without repeatedly asking for
  confirmation. Do not create cloud resources, GitHub repositories, external
  credentials, public DNS, or paid services without explicit authorization.
- Never commit secrets, kubeconfigs, Terraform state, saved plans, tokens,
  passwords, private keys, or generated provider caches.
- Before substantial Terraform work, inspect available MCP/LSP tooling as
  required by the active `AGENTS.md`. Prefer semantic Terraform intelligence if
  a reliable configured integration exists. Otherwise state that briefly and
  use `terraform fmt`, `terraform validate`, provider schemas, plans, and tests.
- Pin versions and image digests after verifying current official sources. Do
  not blindly reuse versions recorded in the retired cluster.
- Keep resource usage suitable for Docker Desktop. Start with one replica and
  short retention unless a checkpoint is explicitly testing scale or failure.

## Verified starting state (2026-07-28)

- The former Minikube profile `learning-cluster` was deliberately deleted.
- Its Docker container, machine directory, and kubeconfig context are gone.
- The former Lab 04 Terraform state contains zero managed resources.
- The old `training` Namespace and `terraform-lab-info` ConfigMap were destroyed
  through an inspected Terraform plan: `0 added, 0 changed, 2 destroyed`.
- The old cluster had no StatefulSet, PersistentVolumeClaim, or application data
  requiring backup.
- The old source repository remains at `C:\Users\kwdow\dev\kub`. It contains
  useful Lab 01-05 history plus a partial Traefik exercise. Treat it as reference
  material only; do not make it an implicit dependency of this capstone.
- The application source repository is `C:\Users\kwdow\dev\zeroapp`.
- The new workspace is `C:\Users\kwdow\dev\kub-capstone`.
- At teardown time the local Terraform executable was v1.15.7. Recheck all tool
  versions. In Windows PowerShell this executable required the complete
  `-out=filename.tfplan` argument to be quoted when saving a plan.
- No cloud spend or cloud credentials are authorized by this document.

The new chat must verify this starting state because local tooling and Docker
Desktop state can change between sessions.

## Capstone outcome

Build a reproducible, no-cost local Kubernetes platform from an empty machine
state, then prove that it can be operated, observed, secured, destroyed, and
rebuilt without hidden cluster state.

The completed platform should include:

- a Terraform-created local Kubernetes cluster;
- a narrowly Terraform-owned Argo CD bootstrap;
- Argo CD reconciliation for in-cluster applications and platform components;
- Traefik ingress with access from the Windows host and another LAN device;
- local DNS behavior and locally trusted TLS;
- zeroapp built and released through CI with immutable image identity;
- PostgreSQL persistence, migration, backup, and tested restore;
- an OpenTelemetry Collector pipeline;
- Prometheus metrics, Loki logs, Tempo traces, and Grafana visualization;
- useful dashboards, alerts, contact points, and notification routing managed by
  a separate Grafana Terraform repository;
- vulnerability scanning, SBOM generation, policy checks, and image provenance;
- GitOps drift detection, self-healing, pruning, promotion, and rollback;
- recovery evidence from both workload failure and complete cluster rebuild;
- an optional, separately authorized cloud translation to AKS, EKS, or GKE.

## Non-overlapping ownership model

| Concern | Authoritative owner | Notes |
| --- | --- | --- |
| Application source and tests | `C:\Users\kwdow\dev\zeroapp` | Go source, Containerfile, tests, image build and publication |
| Local cluster lifecycle | Infrastructure Terraform | Cluster creation, node/network configuration, outputs and destruction |
| Argo CD bootstrap | Bootstrap Terraform | Only the minimum required to make GitOps operational |
| In-cluster platform and workloads | Argo CD | Helm releases and Kubernetes configuration sourced from Git |
| Grafana API resources | Separate Grafana Terraform repository | Data sources, folders, dashboards, alerts, contact points and policies |
| Runtime state | Kubernetes and backing storage | Never treated as the desired-state source |
| Secrets | Protected secret mechanism | Never Git, committed variable files, or plain Terraform outputs |
| Human UIs | Inspection and break-glass only | Permanent changes must return to the authoritative reconciler |

Terraform and Argo CD must never own the same Kubernetes object. Grafana
Terraform must not own the Grafana deployment itself; Argo CD owns that
deployment, while Grafana Terraform owns objects exposed by the Grafana API.

## Intended repositories

The capstone eventually uses three repositories:

1. `zeroapp`: existing application source, tests, container build, and image CI.
2. `kub-capstone`: this infrastructure/GitOps repository.
3. A later `grafana-config` repository: Grafana provider configuration and its
   independently controlled pipeline and state.

Do not create or publish GitHub repositories until the learner explicitly
authorizes the external change. Local Git initialization is safe once the first
architecture decision has been recorded.

## Provisional infrastructure layout

Create this structure incrementally, not all at once:

```text
kub-capstone/
|-- README.md
|-- .gitignore
|-- docs/
|   |-- decisions/
|   `-- runbooks/
|-- terraform/
|   |-- cluster/
|   `-- bootstrap/
|-- gitops/
|   |-- projects/
|   |-- applications/
|   |-- platform/
|   |   |-- ingress/
|   |   |-- database/
|   |   |-- observability/
|   |   `-- policy/
|   `-- workloads/
|       `-- zeroapp/
`-- scripts/
```

The exact layout may change through an architecture decision, but ownership
boundaries must remain visible in the directory structure.

## Definition of done for every checkpoint

A checkpoint is complete only when all applicable items are true:

1. Desired state is stored under the correct owner.
2. Formatting, static validation, and render checks pass.
3. The relevant plan or diff was inspected before mutation.
4. Runtime health is verified through status plus an appropriate behavior test.
5. Failure evidence, events, or logs were checked when diagnosis is part of the
   lesson.
6. Rollback or destruction is known and does not cross ownership boundaries.
7. Production differences and security implications are recorded briefly.
8. No secret or generated state has entered Git.

## Checkpoint roadmap

Check items only after inspecting their evidence. A new chat should continue at
the first unchecked item.

### 0. Fresh-machine and tooling preflight

- [x] Confirm this workspace initially contains only `README.md`.
- [x] Inspect active `AGENTS.md` instructions and available MCP/LSP tools.
- [x] Verify Windows, Docker Desktop, CPU, memory, and free disk capacity.
- [x] Inventory `git`, `terraform`, `docker`, `kubectl`, `helm`, `kind`, `argocd`,
      `curl.exe`, and certificate tooling without installing anything first.
- [x] Confirm there is no active `learning-cluster`, unexpected kube context, or
      leftover cluster container.
- [x] Check whether host ports 80 and 443 are available and identify any LAN and
      Windows Firewall constraints.
- [x] Record actual versions and missing prerequisites.

Verified 2026-07-29:

- Windows 11 Pro build 26200, 16 GiB physical memory.
- Docker Desktop 4.73.1 / Engine 29.4.3, with 12 CPUs and approximately
  7.7 GiB available to the Linux VM.
- Approximately 305 GB free on `C:`.
- Git 2.54.0.1, Terraform 1.15.7, kubectl 1.34.1 with Kustomize 5.7.1,
  Helm 4.2.3, Minikube 1.38.1, and curl 8.21.0.
- Terraform reported that patch release 1.15.8 was available, but the current
  executable is a custom installation under `NoApp\bin` rather than a
  Winget-managed package. Keep 1.15.7 for initial validation and avoid creating
  competing executables on `PATH`. Upgrade through the original installation
  owner before the first cluster apply.
- `kind`, `argocd`, `mkcert`, `openssl`, and `terraform-ls` were not found.
- No Terraform or generic language-server MCP tool was available. Use native
  Terraform formatting, validation, provider schemas, and inspected plans.
- No Minikube profile, active Kubernetes context, or `learning-cluster` Docker
  container remained.
- Ethernet LAN address `10.0.1.74`, gateway `10.0.1.1`.
- Windows Domain, Private, and Public firewall profiles are enabled. Ports 80
  and 443 had no listening process. Any later LAN exposure still requires a
  narrowly scoped inbound firewall rule and an explicit rollback command.

Exit gate: the machine baseline and networking constraints are understood; no
resource has been created.

### 1. Decide how Terraform owns a local cluster

- [x] Research current official Kind documentation, Terraform Registry entries,
      provider maintenance, Windows/Docker behavior, and known limitations.
- [x] Compare these bounded options:
  - Kind plus a maintained community Terraform provider. This is the provisional
    leading choice because it gives Terraform a real cluster lifecycle, but it
    introduces third-party provider risk.
  - Minikube created outside Terraform. Operationally familiar, but it fails the
    explicit capstone goal that Terraform own cluster creation.
  - An official cloud provider. Most enterprise-faithful, but requires explicit
    credentials, budget, quotas, and cleanup authorization.
- [x] Reject wrapping `minikube start` or `kind create cluster` in `local-exec`
      unless an architecture record demonstrates why no real provider is viable;
      provisioners provide weak state, drift, update, and error semantics.
- [x] Decide the CNI early. The selected network must actually enforce
      NetworkPolicy; do not assume a default CNI does.
- [x] Decide ingress port mappings and how Windows/LAN traffic reaches them.
- [x] Record the decision, alternatives, risks, and replacement strategy in
      `docs/decisions/001-local-cluster.md`.

Decision accepted 2026-07-29: use the community `tehcyx/kind` Terraform
provider v0.11.0, its matching Kind v0.31 generation, a digest-pinned Kubernetes
1.35.0 node image, one control-plane node, Kind's built-in network-policy
implementation, loopback-only Kubernetes API access, and explicit Windows/LAN
port mappings for the later Traefik NodePorts. See ADR-001.

Exit gate: one provider/CNI/network design is selected using current primary
sources, with community-provider risk explicitly accepted or rejected.

### 2. Initialize the infrastructure repository

- [x] Create the minimal directory structure needed for cluster Terraform only.
- [x] Add a narrow `.gitignore` for Terraform caches, state, plans, secrets,
      kubeconfigs, temporary output, and local environment files.
- [x] Initialize local Git. Establish a clean baseline commit when authorized.
- [x] Add version constraints and commit provider lock files.
- [x] Add validation commands to the README or a small PowerShell check script.
- [x] Do not publish a remote repository yet unless explicitly authorized.

Validation: `terraform fmt -check -recursive`, `terraform validate`, secret and
ignored-file checks, and `git diff --check`.

### 3. Provision the local cluster with Terraform

- [x] Define a small, pinned cluster with explicit name, node image/version,
      resource assumptions, CNI choice, and ingress port mappings.
- [x] Treat kubeconfig and Terraform state as sensitive local artifacts.
- [x] Produce an inspected saved plan before apply.
- [x] Apply and verify node readiness, system Pods, storage class behavior, DNS,
      CNI health, and actual NetworkPolicy capability.
- [x] Confirm the Docker container/network boundary and the difference between
      Pod IP, Service IP, node/container IP, Windows host IP, and LAN IP.
- [x] Run a no-change Terraform plan.

Rollback: Terraform destroys only the cluster it created. Do not use broad Docker
cleanup commands.

### 4. Bootstrap Argo CD with a separate Terraform root

- [x] Create the narrowly scoped bootstrap root and state.
- [x] Configure Kubernetes and Helm providers from the new cluster connection.
- [x] Install a resource-conscious, non-HA Argo CD with pinned chart and images.
- [x] Define exactly which bootstrap objects Terraform keeps owning.
- [x] Validate Argo CD Pods, API health, CLI access, and UI access.
- [x] Prove a second Terraform plan is empty.
- [x] Write the Argo recovery and Terraform destroy order before adding apps.

Exit gate: Argo CD is healthy, but it does not yet silently own unrelated
resources.

### 5. Publish the infrastructure repository and establish GitOps

- [x] With explicit authorization, create or connect the GitHub infrastructure
      repository and push the reviewed baseline.
- [x] Prefer a public read-only repository for the first lab if no secrets are
      present; otherwise configure credentials through protected secrets.
- [x] Create an Argo CD AppProject with explicit source repositories,
      destinations, namespace policy, and resource allow/deny boundaries.
- [x] Add a root Application or small app-of-apps bootstrap.
- [x] Inspect sync, diff, health, history, and the exact pruning boundary.
- [x] Enable automated sync, pruning, and self-healing only after a manual sync
      proves the boundary is safe.

### 6. Establish ingress, LAN routing, DNS, and TLS

- [ ] Deploy Traefik through Argo CD, not manual Helm and not Terraform.
- [ ] Pin chart/version and configure one bounded replica, metrics, structured
      access logs, resource limits, and an explicit IngressClass.
- [ ] Keep watch scope and RBAC capability distinct and documented.
- [ ] Deploy a temporary echo service and host-based Ingress.
- [ ] Verify routing from inside the cluster, the Windows host, and another LAN
      device. Do not mistake ClusterIP or Pod IP for the Windows LAN address.
- [ ] Configure a stable local DNS approach using a reserved local test domain.
- [ ] Issue locally trusted TLS, distribute trust deliberately, and verify HTTP
      redirect plus certificate hostname and chain.
- [ ] Record Windows Firewall rules and exact rollback.

### 7. Build a trustworthy application image path

- [ ] Review the existing `zeroapp` Containerfile, tests, health endpoints, and
      architecture from its own repository.
- [ ] Choose GHCR or another explicitly approved private/local registry. If a
      Kind-local registry is selected, incorporate its mirror configuration into
      cluster creation rather than hiding it in manual steps.
- [ ] Build and test the image as a non-root user.
- [ ] Add CI for Go tests, vet/static checks, image build, vulnerability scan,
      SBOM generation, publication, and immutable digest output.
- [ ] Add provenance/signing with a maintained standard tool and verify it.
- [ ] Keep credentials in protected secrets and pin deployment by digest.

### 8. Deploy zeroapp through Argo CD

- [ ] Add Namespace, configuration, Deployment, Service, probes, resource
      requests/limits, security context, and disruption/graceful-shutdown rules.
- [ ] Keep environment-specific values in an overlay or Helm values boundary.
- [ ] Add Ingress and TLS using the platform contract from checkpoint 6.
- [ ] Verify UI/API behavior, EndpointSlices, rollout, Pod replacement, and LAN
      access.
- [ ] Prove that an out-of-band edit is detected and reconciled by Argo CD.

### 9. Add PostgreSQL and prove persistence

- [ ] Decide between a direct StatefulSet/Helm chart and an operator, documenting
      why the desktop lab choice differs from a managed production database.
- [ ] Deploy PostgreSQL through Argo CD with a PVC and constrained resources.
- [ ] Store credentials outside Git and deliver them through the chosen secret
      mechanism.
- [ ] Add idempotent, observable schema migrations owned by the application
      release process.
- [ ] Switch zeroapp from memory to PostgreSQL and verify CRUD behavior.
- [ ] Restart/delete Pods and prove data persistence.
- [ ] Create a backup, delete test data, restore it, and record evidence and RTO.

### 10. Build the telemetry platform

- [ ] Define a desktop resource budget and retention policy before installation.
- [ ] Deploy an OpenTelemetry Collector through Argo CD with explicit OTLP
      receivers, batching/memory protection, enrichment, and bounded exporters.
- [ ] Deploy lean Prometheus, Loki, Tempo, and Grafana components through Argo CD.
- [ ] Explicitly distinguish Grafana's metadata database from Prometheus, Loki,
      and Tempo telemetry stores.
- [ ] Keep components internal unless a deliberate access path is required.
- [ ] Verify readiness, storage use, retention, and no-change Argo sync.

### 11. Instrument and observe zeroapp

- [ ] Add or verify bounded-cardinality RED metrics.
- [ ] Emit structured logs without names, emails, bodies, tokens, or secrets.
- [ ] Emit traces with propagated context across HTTP and PostgreSQL operations.
- [ ] Send OTLP to the Collector rather than directly to storage backends.
- [ ] Generate known traffic and correlate a request across metric, log, and
      trace views.
- [ ] Test a controlled error and latency scenario and inspect the evidence.

### 12. Create the separate Grafana configuration repository

- [ ] Create this repository only with explicit external-publication authority.
- [ ] Configure the Grafana Terraform provider without storing credentials in
      source or plan artifacts.
- [ ] Select a remote backend with locking and document recovery.
- [ ] Manage data sources, folders, dashboards, alert rules, contact points, and
      notification policies as code.
- [ ] Use a trusted self-hosted GitHub Actions runner because local Grafana is not
      reachable from a hosted runner.
- [ ] Run format, validate, lint, and non-mutating plan on pull requests.
- [ ] Apply only from the protected default branch after review, with concurrency
      control and protected credentials.
- [ ] Prove that permanent UI drift is detected and reconciled.

### 13. Add namespace, identity, network, and admission controls

- [ ] Apply Pod Security Admission labels deliberately and verify rejection of a
      known-insecure test Pod.
- [ ] Use dedicated service accounts and least-privilege RBAC.
- [ ] Add ResourceQuota and LimitRange where they teach a real ownership rule.
- [ ] Start NetworkPolicy from observed traffic dependencies, then verify both
      allowed and denied connections with the chosen enforcing CNI.
- [ ] Select a lightweight admission-policy approach for required labels,
      approved registries, immutable images, and provenance expectations.
- [ ] Add CI policy tests before enabling enforcement in the cluster.
- [ ] Document break-glass access and rollback.

### 14. Exercise GitOps delivery and rollback

- [ ] Promote a new zeroapp image by immutable digest through a reviewed Git
      change.
- [ ] Observe Argo CD diff, sync, health, and history.
- [ ] Test a deliberately bad release and recover through Git revert or an
      explicitly documented Argo rollback strategy.
- [ ] Test self-healing of a manual mutation.
- [ ] Test pruning with a harmless disposable object before relying on it.
- [ ] Confirm Terraform plans remain unchanged while Argo-owned workloads change.

### 15. Prove operational recovery

- [ ] Delete an application Pod and verify automatic recovery.
- [ ] Stop or replace a node/cluster component and inspect events and telemetry.
- [ ] Restore PostgreSQL from the recorded backup in a controlled test.
- [ ] Re-bootstrap Argo CD from Terraform and recover desired state from Git.
- [ ] Record owners, dependencies, RTO, RPO, and failure gaps in runbooks.

### 16. Destroy and rebuild from zero

- [ ] Capture final inventory, Git revisions, image digests, backup evidence,
      Terraform states, and Argo application health without committing secrets.
- [ ] Destroy in reverse ownership order: disposable workloads/data only after
      backup proof, Argo bootstrap, then the Terraform-owned cluster.
- [ ] Verify exact profile, container, kubeconfig, state, firewall, certificate,
      DNS, runner, and external-repository remnants.
- [ ] Rebuild from the documented sources on an empty local cluster state.
- [ ] Restore data and verify UI/API, LAN TLS, dashboards, alerts, metrics, logs,
      traces, policy, and GitOps reconciliation.
- [ ] Record total rebuild and restore time.

### 17. Optional cloud translation

- [ ] Proceed only with explicit provider, credentials, region, budget, quota,
      networking, and cleanup authorization.
- [ ] Map local cluster, ingress, identity, storage, database, secret, registry,
      observability, and state decisions to AKS, EKS, or GKE.
- [ ] Use the official Terraform provider and remote locked state.
- [ ] Estimate cost before apply, enforce a short lifetime, and verify cleanup and
      billing after destroy.

## Required validation toolbox

Use only tools applicable to the current checkpoint, but do not claim completion
without proportional verification:

- Terraform: `fmt`, `validate`, inspected saved `plan`, `apply`, no-change plan,
  state inspection, and deliberate destroy planning.
- Kubernetes: client/server dry run, schema validation, `kubectl diff`, waits,
  rollout status, events, logs, EndpointSlices, auth checks, and behavior tests.
- Helm: repository provenance where available, pinned chart, `lint`, `template`,
  values/schema validation, and rendered security inspection.
- Argo CD: diff, sync, health, history, ownership boundaries, pruning and
  self-healing tests.
- Application: Go formatting, tests, race/static checks where practical, image
  inspection, HTTP/UI/CRUD checks, graceful termination, and migration tests.
- Supply chain: vulnerability scan, SBOM, digest, signature/provenance
  verification, and policy-test evidence.
- Observability: known fresh traffic, bounded metric labels, trace lookup, log
  query, dashboard query, alert firing and recovery.
- Recovery: destructive tests only after backups and exact targets are verified.

## Security and cleanup rules

- Resolve exact paths, cluster names, Terraform states, namespaces, and external
  targets before destructive actions.
- Never run broad Docker, filesystem, cloud, registry, or GitHub cleanup.
- Prefer reversible operations and reviewed plans.
- Backups are not proven until a restore succeeds.
- Quota is not capacity, and successful resource deletion is not proof that
  billing stopped; verify both when using cloud resources.
- Local certificates and firewall rules are external state and must appear in
  inventory and teardown runbooks.
- A smoke test proves plumbing, not production readiness or performance.

## First checkpoint for the new chat

Start with checkpoint 0 as one coherent read-only preflight. Then research and
write the checkpoint-1 architecture decision before installing a provider or
creating a cluster. The first substantial mutation should be the reviewed local
Git/Terraform skeleton after that decision—not a manually created Kubernetes
cluster.
