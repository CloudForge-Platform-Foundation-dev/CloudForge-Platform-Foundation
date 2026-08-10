# ADR-003: Three-Tier Governance Model

## Status

✅ Approved

## Context

CloudForge needs a governance structure that ensures consistency without becoming a bottleneck. We need clear decision-making authority for architecture, security, and engineering standards.

## Problem Statement

How do we organize governance to:
- Maintain enterprise consistency
- Avoid single points of failure
- Enable fast decision-making for Studios
- Ensure security and compliance

## Considered Options

### Option A: Centralized Governance Board
Single board decides everything.

**Pros:**
- Consistent decisions
- Simple structure

**Cons:**
- Bottleneck
- Studios wait for approvals
- Board becomes overloaded

### Option B: Fully Decentralized
Each Studio governs itself.

**Pros:**
- Fast decisions
- Studio autonomy

**Cons:**
- Architectural drift
- Inconsistent security
- No shared standards

### Option C: Three-Tier Governance (Selected)

```
Enterprise Governance
         │
    ┌────┴────┐
    │         │
    ▼         ▼
Architecture   Security
   Board         Board
    │             │
    └──────┬──────┘
           │
           ▼
   Engineering Board
           │
           ▼
   CloudForge Platform Foundation
           │
           ▼
      CloudForge Studios
```

**Pros:**
- Clear separation of concerns
- Parallel decision-making
- Foundation acts as enforcement layer
- Studios inherit standards automatically

**Cons:**
- More complex structure
- Need coordination between boards

## Decision

Adopt **Three-Tier Governance**:

| Tier | Board | Responsibility |
|------|-------|----------------|
| 1 | Architecture Board | Platform architecture, tech choices, ADR approval |
| 1 | Security Board | Security policies, threat models, compliance |
| 2 | Engineering Board | Coding standards, CI/CD, tooling |
| 3 | Platform Foundation | Standard enforcement, validation, documentation |
| 4 | Studios | Business logic, UX, Studio-specific ADRs |

## Consequences

### Positive
- Architecture and security decisions happen in parallel
- Engineering standards can evolve independently
- Foundation provides automated enforcement
- Studios focus on business value

### Negative
- Need regular sync between boards
- Risk of conflicting decisions

## Mitigations

1. Monthly cross-board sync meeting
2. Conflicts escalated to Enterprise Governance Council
3. All decisions recorded as ADRs
4. Foundation repo serves as SSOT for all standards

## References

- [docs/governance/governance-model.md](../governance/governance-model.md)
- [CONTRIBUTING.md](../../CONTRIBUTING.md)

---

*Decided: 2026-08-10*
*Author: CloudForge Architecture Board*
