# Master Index

> Central navigation hub for all CloudForge Platform Foundation documentation.

---

## 📚 Documentation Map

### Getting Started
| Document | Status | Description |
|----------|--------|-------------|
| [README.md](README.md) | ✅ Approved | Repository overview |
| [docs/getting-started.md](docs/getting-started.md) | ✅ Approved | Onboarding guide for new contributors |

### Architecture
| Document | Status | Description |
|----------|--------|-------------|
| [docs/architecture/platform-architecture.md](docs/architecture/platform-architecture.md) | 🔄 Draft | Enterprise architecture blueprint |

### Governance
| Document | Status | Description |
|----------|--------|-------------|
| [docs/governance/governance-model.md](docs/governance/governance-model.md) | 🔄 Draft | Governance model and review process |

### Security
| Document | Status | Description |
|----------|--------|-------------|
| [docs/security/security-baseline.md](docs/security/security-baseline.md) | 🔄 Draft | Security baseline and hardening guide |

### Standards
| Document | Status | Description |
|----------|--------|-------------|
| [docs/standards/engineering-standards.md](docs/standards/engineering-standards.md) | 🔄 Draft | Coding and development standards |
| [docs/standards/api-standards.md](docs/standards/api-standards.md) | 🔄 Draft | API design guidelines |
| [docs/standards/naming-conventions.md](docs/standards/naming-conventions.md) | 🔄 Draft | Naming conventions across all repos |

### Data Model
| Document | Status | Description |
|----------|--------|-------------|
| [docs/data-model/canonical-data-model.md](docs/data-model/canonical-data-model.md) | 🔄 Draft | Canonical data model specification |
| [schemas/canonical/entity.schema.json](schemas/canonical/entity.schema.json) | ✅ Approved | Base entity schema |
| [schemas/canonical/event.schema.json](schemas/canonical/event.schema.json) | ✅ Approved | Base event schema |

### AI Agents
| Document | Status | Description |
|----------|--------|-------------|
| [docs/agents/ai-agent-specifications.md](docs/agents/ai-agent-specifications.md) | 🔄 Draft | AI agent specifications |

### Architecture Decision Records (ADR)
| ADR | Status | Title |
|-----|--------|-------|
| [ADR-001](docs/adr/001-multi-repo-vs-mono-repo.md) | ✅ Approved | Multi-Repo vs Mono-Repo Architecture |
| [ADR-002](docs/adr/002-json-schema-for-canonical-model.md) | ✅ Approved | JSON Schema for Canonical Data Model |
| [ADR-003](docs/adr/003-three-tier-governance.md) | ✅ Approved | Three-Tier Governance Model |

---

## 🗂️ Repository Structure

```
CloudForge-Platform-Foundation
│
├── README.md                 # Entry point
├── MASTER_INDEX.md           # This file — navigation hub
├── CONTRIBUTING.md           # Contribution guidelines
├── SECURITY.md               # Security policy
├── CHANGELOG.md              # Release history
├── ROADMAP.md                # Future plans
├── VERSION                   # Current version
│
├── docs/                     # Documentation
│   ├── getting-started.md
│   ├── architecture/
│   ├── governance/
│   ├── security/
│   ├── standards/
│   ├── data-model/
│   ├── agents/
│   └── adr/
│
├── schemas/                  # Machine-readable standards
│   ├── canonical/
│   └── api/
│
├── policies/                 # Enforceable policies
│   ├── security/
│   └── naming/
│
├── templates/                # Reusable templates
│   ├── studio-template/
│   └── adr-template.md
│
├── examples/                 # Reference implementations
│
├── scripts/                  # Validation scripts
│
└── .github/                  # GitHub configuration
    ├── workflows/
    ├── ISSUE_TEMPLATE/
    ├── CODEOWNERS
    └── PULL_REQUEST_TEMPLATE.md
```

---

## 🏷️ Version Compatibility

| Foundation Version | Compatible Studio Versions |
|-------------------|---------------------------|
| v0.1.0 | Studio >= v0.1.0 |

See [CHANGELOG.md](CHANGELOG.md) for breaking changes and migration guides.
