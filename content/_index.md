---
title: "DevSecOps Induction"
description: "Concise induction for secure cloud-native delivery aligned to DTT ADRs."
weight: 1
icon: "graduation-cap"
---

Use this page as the starting point for the repository. The goal is not to finish every tutorial; it is to produce evidence that you can deliver, secure, and operate a small cloud-native workload.

**Evidence beats course completion.** For each section, produce one artefact: a pull request, diagram, runbook, threat model, test, or short demo.

## 1. Operating Rules

| Rule | What good looks like |
|------|----------------------|
| Learn by doing | Run the local labs before the AWS labs. Explain the commands, manifests, and failure modes. |
| Keep work reproducible | Source-controlled config, repeatable `just` recipes, pinned tools via `mise`, and no undocumented console changes. |
| Validate early | Run format, tests, Trivy/IaC checks, and focused security review before merge or deploy. |
| Keep humans accountable | Automation and AI can assist, but people approve consequential changes. |

Start here:

```bash
just prereqs
just deploy-local
just docs-serve
```

Then follow the [learning path](learning-path.md).

## 2. ADR-Aligned Delivery Checklist

The repository examples are intentionally small, but the habits should match DTT architecture decisions.

| Area | ADR expectation | Practice in this repo |
|------|-----------------|-----------------------|
| Configuration management | [ADR 010](https://adr.dtt.digital.wa.gov.au/operations/010-configmgmt.html): infrastructure is reproducible from Git; validate with Trivy plus `terraform plan` or `kubectl diff`; use tagged releases for higher environments. | Study `kustomize/`, `eksauto/terraform/`, and `just lint`. Avoid manual drift; prefer a reviewed manifest, plan, or recipe change. |
| CI/CD | [ADR 004](https://adr.dtt.digital.wa.gov.au/development/004-cicd.html): build, test, scan, analyse, release; keep unprivileged CI in GitHub Actions; run AWS-privileged deployment from controlled operations runners with assumed roles. | This site uses GitHub Actions only for unprivileged static publishing. Treat AWS examples as local/controlled operations work unless a runner and role boundary are explicitly approved. |
| Workloads | [ADR 002](https://adr.dtt.digital.wa.gov.au/operations/002-workloads.html): use CNCF-certified Kubernetes; prefer AWS EKS Auto Mode for cloud workloads; keep durable state in managed services where practical. | Learn locally with k3d, then compare with `eksauto/`. Note where demo databases use cluster storage and where production would use managed database, object, or shared file services. |
| AI governance | [ADR 011](https://adr.dtt.digital.wa.gov.au/security/011-ai-governance.html): start with low-risk, non-sensitive tasks; set explicit workspace/tool/model boundaries; require human approval for production, release, customer, or high-impact actions. | Use `oy` for repository explanation, coding help, and audits. Do not give AI broad credentials, sensitive data, or autonomous deploy authority. Keep prompts, outputs, tool calls, and approvals reviewable. |

## 3. Core Skills to Build

| Skill | Learn | Prove it |
|------|-------|----------|
| Git and review | Branches, commits, pull requests, small changes. | Open a small documentation or manifest PR. |
| Local tooling | `mise`, `just`, Docker, k3d, kubectl, k9s. | Run `just prereqs`, `just deploy-local`, and inspect pods. |
| Kubernetes config | Namespaces, Deployments, Services, PVCs, Kustomize overlays. | Explain `kubectl kustomize kustomize/overlays/local`. |
| Infrastructure as Code | Terraform plan/apply/destroy, state, drift, tagging. | Read `eksauto/terraform` and run `terraform fmt -check`. |
| Secure delivery | Trust boundaries, validation, least privilege, audit evidence. | Add one focused test or scan for a change. |

Useful references:

- [GitHub learning resources](https://docs.github.com/en/get-started/start-your-journey/git-and-github-learning-resources)
- [Kubernetes basics](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
- [Terraform language](https://developer.hashicorp.com/terraform/language)
- [OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/)
- [ACSC ISM](https://www.cyber.gov.au/resources-business-and-government/essential-cyber-security/ism)

## 4. Hands-On Path

1. [Getting started](getting-started.md) - local tools and first cluster.
2. [Kustomize](examples/kustomize.md) - base Kubernetes resources and overlays.
3. [rclone CSI](examples/rclone.md) - local object-storage-style filesystem mount.
4. [Apps SSO](examples/apps-sso.md) - apps behind Keycloak, oauth2-proxy, and Traefik.
5. [Drupal Hugo/DDEV](examples/drupal.md) - local PHP/Drupal workflow.
6. [EKS Auto Mode](examples/eksauto.md) - managed Kubernetes with Terraform.
7. [S3 Pod Identity](examples/s3-pod-identity.md) - credential-free AWS access from pods.
8. [External Secrets](examples/secrets.md) - sync cloud secrets into Kubernetes.
9. [ArgoCD](examples/argocd.md) - GitOps reconciliation.

Cost warning: AWS labs create billable resources. Destroy them when finished.

## 5. Baseline Commands

```bash
just lint       # local validation, including docs build
oy audit        # AI-assisted review; keep outputs human-reviewed
```

When adding a security control, name the trust boundary, validate near that boundary, fail closed, and add a focused test.

## 6. Optional Learning Resources

Keep optional resources purposeful:

- [Obsidian](https://obsidian.md/) or plain Markdown for notes.
- [Bloom's taxonomy](https://en.wikipedia.org/wiki/Bloom%27s_taxonomy) to self-check understanding.
- [SANS SEC540](https://www.sans.org/cyber-security-courses/cloud-security-devops-automation/) for cloud security and DevSecOps depth.
- [SANS SEC522](https://www.sans.org/cyber-security-courses/application-security-securing-web-apps-api-microservices/) for web/API security.
- [CKA, CKAD, or CKS](https://training.linuxfoundation.org/certification/) when Kubernetes certification is useful evidence.
