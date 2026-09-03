# Contributing to CloudForge Platform Foundation

> Thank you for investing your time in contributing to our project!

---

## 🔄 Contribution Workflow

```
Issue / Proposal
        │
        ▼
Architecture Discussion (GitHub Discussion)
        │
        ▼
RFC (if needed) → ADR (if significant)
        │
        ▼
Implementation + Documentation + Tests
        │
        ▼
Validation (scripts/validate.sh)
        │
        ▼
Pull Request
        │
        ▼
Review & Approval (minimum 2 approvers)
        │
        ▼
Merge into Main
```

---

## 📋 Pull Request Requirements

Before submitting a PR, verify:

- [ ] Architecture complies with Platform Standards
- [ ] Documentation updated in the same PR
- [ ] CHANGELOG.md updated
- [ ] VERSION updated (if applicable)
- [ ] ADR created for significant architectural decisions
- [ ] Security implications reviewed
- [ ] `scripts/validate.sh` passes locally
- [ ] CI pipeline passes

---

## 🏗️ Architecture Decision Records (ADR)

Any decision that affects:
- Technology selection
- Architectural patterns
- Data model changes
- Security model changes
- API strategy

Must include an ADR using the template at [templates/adr-template.md](templates/adr-template.md).

---

## 📝 Documentation Standards

- Use Markdown for all documentation
- Keep line length <= 100 characters where practical
- Include diagrams using Mermaid or ASCII art
- Update MASTER_INDEX.md status when changing document state

---

## 🔒 Security

See [SECURITY.md](SECURITY.md) for reporting vulnerabilities.

---

## 💬 Questions?

Open a [GitHub Discussion](https://github.com/CloudForge-Platform-Foundation-dev/CloudForge-Platform-Foundation/discussions) for architecture proposals.
