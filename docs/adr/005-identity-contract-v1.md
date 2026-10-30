# ADR-005: Adopt Identity Contract v1 as the platform JWT standard

## Status

📄 Proposed

## Context

CloudForge Studios authenticate callers with JWTs issued by the CloudForge Identity Service. Before a shared contract existed, two Studios disagreed on the shape of the permissions claim: Ingest used `scopes` as a list, Knowledge used `scope` as a space-separated string. A token that one Studio accepted could therefore be rejected by the other.

What Foundation says today (checked on `main`):

- `docs/standards/api-standards.md` states only "Authentication: Bearer JWT".
- `schemas/api/api-spec-template.yaml` defines `BearerAuth` (bearer, JWT) and says the token comes from the CloudForge Identity Service.
- `docs/security/security-baseline.md` calls for OAuth 2.0 / OIDC for user authentication.
- No Foundation document defines the claims, the scope format, the signature rules or the error semantics, and there is no registry of scope namespaces.

Implementation state as of 2026-10-17: `cloudforge-auth-core` implements the contract (tag `v1.1.8`), and Ingest, Knowledge, Nova and Security all pin it. Three repositories (`cloudforge-deployment-studio`, `cloudforge-e2e`, `cloudforge-infra-terraform`) do not reference it.

## Problem Statement

The shared behaviour exists only as code in one library and as a draft document outside Foundation. Nothing prevents a new Studio, or a copy-pasted verifier, from reintroducing drift, and Foundation's own gates cannot check for it.

## Considered Options

### Option A: Keep the contract inside the `cloudforge-auth-core` repository

**Pros:**
- Lives next to the implementation.

**Cons:**
- Not covered by Foundation governance or gates.
- Studios that do not use the library have no normative reference.
- Foundation has no ownership of the contract's versioning.

### Option B: Adopt the contract as a Foundation standard and add a gate (chosen)

**Pros:**
- One normative source, versioned independently of the library (`identity-contract-v1`, `identity-contract-v2`).
- Checkable in CI, consistent with the Smart Gate model of ADR-004.

**Cons:**
- One more document to keep in sync with the implementation.
- Gate rules can produce false positives if their patterns are too broad.

### Option C: Do nothing

**Pros:**
- No work.

**Cons:**
- Drift can recur silently.

## Decision

Adopt Option B.

1. **Standard.** `docs/standards/identity-contract.md` becomes Foundation's standard for platform JWTs. It is versioned independently of `cloudforge-auth-core`. A breaking change requires `identity-contract-v2`, a migration guide and a deprecation window (contract section 6).
2. **Claims shape (contract section 2).** Permissions are carried in `scope`, a space-separated string. A `scopes` array is not allowed and is rejected with `401`, even if a valid `scope` is also present.
3. **Error semantics (contract section 5)** are mandatory. This includes `503` when the JWKS endpoint is unreachable, and `403` when an otherwise valid token has no `scope` claim or has `scope: null`. The `null` handling documents current `cloudforge-auth-core` behaviour, locked by regression tests since `v1.1.8`. It is not a long-term decision and changes only through the amendment process in contract section 6.
4. **Scope namespaces** are registered at namespace level in Appendix A of the contract. `ingest`, `knowledge`, `nova` and `security` are the initial entries. Permission-level entries are added once the owning Studio has confirmed which scopes it enforces. `nova:query`, `security:read` and `security:write` appear in the Identity Service allowlist but are not yet confirmed.
5. **Gate rule (contract section 8)** is implemented in a follow-up PR, not in this one. It covers: (a) endpoints that enforce auth declare both `401` and `403`; (b) Studios take auth logic from `cloudforge-auth-core`; (c) the token claim `scopes` is not read. The pattern for (c) must be narrow enough not to flag a `scopes` field in a token-request body. How each check is expressed (a new script invoked from the Studio template, or a Spectral rule for the OpenAPI part) is decided in the implementing PR; the rule will not extend `scripts/validate-studio.sh`, whose header states that it deliberately does not cover contract compliance. It starts in warning mode and becomes failing once all Studios pass it.
6. **Governance workflows are untouched.** This ADR does not change `.github/workflows/governance-guard.yml` or `.github/workflows/foundation-validation.yml`. The Studio template change in the follow-up PR affects newly generated Studios only; existing Studios adopt through their own PRs.
7. **Scope of the standard.** It covers JWTs issued by the Identity Service for platform APIs, and builds on `api-standards.md` (Authentication: Bearer JWT). It does not replace the OAuth 2.0 / OIDC requirement for user authentication in the security baseline. Machine-to-machine token issuance is addressed in ADR-007.
8. **Approval.** Foundation has a single maintainer (see ADR-004), so there is no independent reviewer. This ADR merges as Proposed. Promotion to Approved is a separate PR, made after the gate rule has run in warning mode against the four Studios.

## Consequences

### Positive

- One normative reference for the JWT shape, the scope format and the error behaviour.
- Drift between Studios becomes detectable in CI.
- The contract has Foundation-level versioning, separate from library releases.

### Negative

- Foundation takes on a standard that mirrors an external implementation, so the two can diverge.
- Documenting `scope: null` as current behaviour could be mistaken for design intent.
- Existing Studios have different CI layouts (`validate-against-foundation.yml` in some, `ci.yml` in others), so rolling out the gate is a per-Studio change.

## Mitigations

- The contract states that it follows implementation behaviour and records the `null` handling as non-final.
- The gate starts in warning mode, with narrow patterns and positive and negative tests under `scripts/tests/`.
- Registry entries are added at permission level only after the owning Studio confirms them.

## Alternatives Considered

Options A and C above were rejected. Folding the machine-to-machine question into this ADR was also rejected: the contract excludes M2M issuance policy, and the two decisions can be approved independently (see ADR-007).

## References

- [Identity Contract v1](../standards/identity-contract.md)
- [ADR-003: Three-Tier Governance](003-three-tier-governance.md)
- [ADR-004: Smart Gate Governance](004-smart-gate-governance.md)
- [ADR-007: M2M service token issuance policy](007-m2m-service-token-issuance-policy.md)
- [API standards](../standards/api-standards.md), [Security baseline](../security/security-baseline.md)
- RFC 7519 (JWT), RFC 9068 (JWT Profile for OAuth 2.0 Access Tokens), RFC 8725 (JWT Best Current Practices), RFC 6749 section 3.3 (scope)

---

*Decided: (set when the status changes to Approved)*
*Author: (maintainer to fill in)*
