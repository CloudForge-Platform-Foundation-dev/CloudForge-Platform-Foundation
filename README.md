# CloudForge Platform Foundation

> **The Enterprise Foundation of the CloudForge AI Ecosystem**

**One Platform • Many Studios • Shared Knowledge • Enterprise Governance**

---

## 🎯 What is this?

CloudForge Platform Foundation is the **central enterprise repository** that defines architectural standards, governance, security policies, engineering principles, and shared knowledge for the entire CloudForge ecosystem.

It serves as the **Single Source of Truth (SSOT)** that every CloudForge Studio depends upon.

> ⚠️ **This repository does NOT implement business applications.** It provides standards, schemas, policies, and templates that Studios consume.

---

## 🚀 Quick Start

| Step | Action | Time |
|------|--------|------|
| 1 | Read [docs/getting-started.md](docs/getting-started.md) | 5 min |
| 2 | Review [MASTER_INDEX.md](MASTER_INDEX.md) for navigation | 2 min |
| 3 | Explore [schemas/](schemas/) for reusable data models | 5 min |
| 4 | Use [templates/studio-template/](templates/studio-template/) to bootstrap a new Studio | 10 min |
| 5 | Read [CONTRIBUTING.md](CONTRIBUTING.md) before proposing changes | 5 min |

---

## 🏛️ Platform Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Experience Layer                          │
│         (Web Portal • CLI • API • SDK • Mobile)             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Studio Layer                            │
│   Ingest • Nova • Security • Knowledge • Compliance • ...   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                 Shared Platform Services                     │
│   IAM • API Gateway • Workflow • Audit • Secrets • AI GW    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│           ☁️ CloudForge Platform Foundation ☁️               │
│   Architecture • Governance • Security • Data Model • ADR   │
└─────────────────────────────────────────────────────────────┘
```

---

## 📦 What's Inside

| Directory | Purpose |
|-----------|---------|
| `docs/` | All documentation: architecture, governance, security, standards |
| `schemas/` | JSON Schema, OpenAPI specs, and canonical data models |
| `policies/` | OPA/Rego policies, linting rules, and validation configs |
| `templates/` | Reusable templates: Studio bootstrap, ADR template |
| `examples/` | Sample implementations and reference architectures |
| `scripts/` | Validation and linting scripts |

---

## 🛡️ Core Principles

- **Security by Default** — Mandatory, not optional.
- **Architecture Before Implementation** — Design first, code second.
- **Documentation First** — Docs are part of the product.
- **Single Source of Truth** — Standards exist once, consumed everywhere.
- **Immutable Data** — Raw data never changes; transformations create new versions.
- **API First** — Every capability is API-accessible.
- **Cloud Agnostic** — Portable across AWS, Azure, GCP.

---

## 📋 Repository Standards Checklist

Every CloudForge repository must include:

```
README.md
MASTER_INDEX.md
ROADMAP.md
CHANGELOG.md
VERSION
LICENSE
SECURITY.md
CONTRIBUTING.md
CODE_OF_CONDUCT.md
SUPPORT.md

.github/
    workflows/
    ISSUE_TEMPLATE/
    PULL_REQUEST_TEMPLATE.md
    CODEOWNERS
```

---

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full workflow.

> **Quality over quantity.** Every contribution should improve consistency, security, or maintainability.

---

## 📜 License

See [LICENSE](LICENSE) file for details.

---

**Design Once. Reuse Everywhere. Scale Without Limits.**

<!-- test: P0-6 smart gate positive case -->
