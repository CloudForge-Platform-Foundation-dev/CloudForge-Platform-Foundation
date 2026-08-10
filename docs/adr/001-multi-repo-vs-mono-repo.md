# ADR-001: Multi-Repository Architecture vs Mono-Repository

## Status

✅ Approved

## Context

CloudForge is designed as an enterprise AI platform with multiple specialized Studios (Ingest, Nova, Security, Knowledge, etc.). We need to decide whether to organize code in a single mono-repository or multiple independent repositories.

## Problem Statement

We must choose a repository strategy that balances:
- Independent release cycles for each Studio
- Shared standards and governance
- Code isolation between business domains
- Developer experience and onboarding
- CI/CD complexity

## Considered Options

### Option A: Mono-Repository
All code (Foundation + all Studios) in one repository.

**Pros:**
- Atomic changes across components
- Single CI/CD pipeline
- Easy code sharing

**Cons:**
- Tight coupling risk
- Scale issues as platform grows
- Harder access control per domain
- All Studios forced to same release cycle

### Option B: Multi-Repository (Selected)
Foundation as central standards repo; each Studio in its own repo.

**Pros:**
- Independent release cycles
- Clear ownership boundaries
- Scales with organization growth
- Studios can use different tech stacks if needed
- Foundation remains independent

**Cons:**
- Cross-repo changes require coordination
- More CI/CD pipelines to maintain
- Dependency management complexity

### Option C: Hybrid (Monorepo for Studios, Separate Foundation)
Studios in one repo, Foundation separate.

**Pros:**
- Studios can share code
- Foundation stays independent

**Cons:**
- Still couples Studios together
- Violates "independent evolution" principle

## Decision

We adopt **Option B: Multi-Repository** with the following structure:

```
cloudforge-platform-foundation (standards)
├── cloudforge-ingest-studio
├── cloudforge-nova-studio
├── cloudforge-security-studio
└── ...
```

## Consequences

### Positive
- Each Studio owns its release cycle
- Foundation standards can evolve independently
- Clear repository boundaries match team boundaries
- New Studios can be added without affecting existing ones

### Negative
- Need automated validation to ensure Studios follow Foundation standards
- Cross-cutting changes require multiple PRs
- Need shared GitHub Actions / workflows

## Mitigations

1. Provide `templates/studio-template/` for consistent repo setup
2. Automated validation via `scripts/validate.sh`
3. Shared GitHub Actions in Foundation that Studios reference
4. Quarterly architecture sync meetings

## Alternatives Considered

See "Considered Options" above.

## References

- [MASTER_INDEX.md](../../MASTER_INDEX.md)
- [docs/architecture/platform-architecture.md](../architecture/platform-architecture.md)

---

*Decided: 2026-08-10*
*Author: CloudForge Architecture Board*
