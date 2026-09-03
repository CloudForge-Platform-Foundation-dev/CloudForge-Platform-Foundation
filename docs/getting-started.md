# Getting Started with CloudForge Platform Foundation

> New here? Start here. ⏱️ ~10 minutes

---

## What You'll Learn

1. What the Platform Foundation is (and isn't)
2. How Studios consume standards from this repo
3. How to validate your Studio against Foundation standards
4. How to contribute

---

## 1. Understanding the Foundation

The **CloudForge Platform Foundation** is a **standards repository**.

It does NOT contain:
- ❌ Business logic
- ❌ Customer data
- ❌ Production services
- ❌ Runtime configurations

It DOES contain:
- ✅ Enterprise architecture standards
- ✅ Security policies (machine-readable)
- ✅ Canonical data models (JSON Schema)
- ✅ API standards (OpenAPI templates)
- ✅ Engineering standards
- ✅ Architecture Decision Records (ADRs)

---

## 2. How Studios Use the Foundation

```
┌─────────────────────┐
│   Your Studio Repo  │
│                     │
│  ┌───────────────┐  │
│  │ Business Logic│  │
│  └───────────────┘  │
│         │           │
│  ┌───────────────┐  │
│  │ CI/CD Pipeline │ │
│  │  - Validate   │  │
│  │    schemas    │  │
│  │  - Check      │  │
│  │    policies   │  │
│  └───────────────┘  │
│         │           │
│         ▼           │
│  Pulls standards    │
│  from Foundation    │
└─────────────────────┘
```

### Quick Integration

1. Copy `templates/studio-template/` to your new Studio repo
2. Update `.github/workflows/validate-against-foundation.yml`
3. Reference schemas from `schemas/canonical/`
4. Follow naming conventions from `docs/standards/naming-conventions.md`

---

## 3. Validating Your Studio

Run the validation script locally:

```bash
# Clone the Foundation repo
git clone https://github.com/CloudForge-Platform-Foundation-dev/CloudForge-Platform-Foundation.git

# Run validation against your studio
cd your-studio-repo
../CloudForge-Platform-Foundation/scripts/validate.sh .
```

This checks:
- ✅ Required files exist (README, CHANGELOG, etc.)
- ✅ JSON Schema compliance
- ✅ Naming convention compliance
- ✅ Security policy presence

---

## 4. Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for the full process.

Quick path for documentation fixes:
1. Fork the repo
2. Create a branch: `git checkout -b docs/your-fix`
3. Make changes
4. Run `scripts/validate.sh`
5. Submit PR

---

## Next Steps

- 📖 Read [docs/architecture/platform-architecture.md](architecture/platform-architecture.md)
- 🔒 Review [docs/security/security-baseline.md](security/security-baseline.md)
- 📐 Check [schemas/canonical/](../schemas/canonical/)
- 🏗️ Explore [templates/studio-template/](../templates/studio-template/)
