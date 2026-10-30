# ADR-007: M2M service token issuance policy

## Status

✅ Approved

## Context

Identity Contract v1 and ADR-005 define the claims, signature rules and error semantics
for platform JWTs. ADR-006 decided that machine-to-machine (M2M) tokens issued by the
Identity Service follow that same contract, and it left five issuance-policy items
undecided. Its Decision 4 says that once those items are answered, the contract is
amended (additively) or ADR-006 is superseded.

Nova already calls Knowledge with a client-credentials token that carries `knowledge:read`.
Ops Studio is planned as a second M2M caller: it reads runbooks from Knowledge and findings
from Security to analyze incidents and propose plans for a human to approve, and it issues
no remediation commands.

Basis for the answers below: a read-only review of the Identity Service code on 2026-10-28
(targeted searches, not a full-file review) and the owner's decisions of the same date.
Implementation-level detail is kept out of this public document. Statements marked
"inferred" come from reading code and have not been tested.

## Problem Statement

- The M2M issuance policy is not written down in Foundation, and ADR-006 cannot record the
  answers without being rewritten.
- A second M2M client should not be added without a recorded policy on scopes, secrets,
  lifetime and empty scopes.
- One of the five items, where the signing key is stored in production, is still not verified.

## Considered Options

### Option A: A new ADR carries the policy and supersedes ADR-006 (chosen)

**Pros:**
- One self-contained record of the issuance policy.
- ADR-006 keeps its history unchanged while it is still Proposed.
- Follows a route that ADR-006 Decision 4 names.

**Cons:**
- Two ADRs describe M2M tokens until ADR-006 is marked Superseded.
- Documents that point to ADR-006 need a follow-up update.

### Option B: Amend Identity Contract v1 additively

**Pros:**
- The policy sits next to the claims it relates to.

**Cons:**
- Every Studio depends on the contract, and operational conditions such as the rotation
  procedure and pre-production tests change more often than a standard should.

### Option C: Add the answers to ADR-006

**Cons:**
- Conflicts with its Consequences (the issuance policy "stays undocumented until the open
  items above are answered") and with the two routes named in its Decision 4.
- Rewrites an ADR that is still under discussion.

## Decision

Adopt Option A.

1. Carried forward from ADR-006 Decision 1: M2M tokens issued by the Identity Service are
   JWTs that conform to Identity Contract v1: claims, signature rules and error semantics.
   `sub` identifies the service account. A receiving Studio verifies them through the same
   path as any other token.
2. Carried forward from ADR-006 Decision 2: The name of the field used to request scopes in
   a token-endpoint request body belongs to the Identity Service API, not to the JWT claims
   contract. The gate rule for the claim `scopes` must not flag it.
3. Issuance policy (owner decisions of 2026-10-28, proposed here until this ADR is Approved):
   - **Scopes.** The Ops Studio client may request only `knowledge:read` and
     `security:read`. The existing per-client allowlist mechanism stays for now. The client
     identifier is decided in the pull request that adds the client.
   - **Client secret rotation.** The current behavior is documented. The Identity Service is
     not changed now to support overlapping old and new secrets. This covers client secrets
     only, not signing-key rotation.
   - **Service token lifetime.** The existing default lifetime is kept, with no per-client
     lifetimes, and no token identifier or revocation mechanism is added now.
   - **Empty scope.** The current behavior is documented and the Identity Service is not
     changed now. Receiving Studios are expected to answer `403` as Identity Contract v1
     specifies for a valid token with insufficient scope, including an empty `scope` string.
4. **Not decided here:** where the signing key is stored in production.
   `TBD — production key storage not verified.` The signing key is not rotated (earlier
   owner decision).
5. Pre-production conditions:
   - Test a secret rotation procedure, including coordination between the Identity Service
     and Ops and a check that a newly requested token is issued. Confirm the effect on
     tokens issued before rotation.
   - Test that Knowledge and Security answer `403` to a valid token with an empty scope,
     and keep the result as evidence.
   - Verify the signing key storage and the token lifetime used in production.
   - Ops client requirements (proposed, not observed in Nova, not in Identity Contract v1):
     always request explicit scopes, never an empty scope; request a new token when fewer
     than 60 seconds of lifetime remain.
6. ADR-006 is marked Superseded, and references to it are updated, in a follow-up change
   after this ADR is Approved. Until then ADR-006 stays Proposed and unchanged.

## Consequences

### Positive

- The M2M issuance policy has one record, and four of ADR-006's five items are answered.
- The Ops client can be added under a written scope limit.
- Pre-production conditions are explicit.

### Negative

- Rotating a client secret can make that client's token requests fail while the two sides
  differ. Tokens issued before a rotation are inferred to remain valid until they expire
  (inferred from the code, not tested).
- Service tokens cannot be revoked before expiry. A leaked token is usable until it expires,
  so the exposure window is bounded by the configured lifetime. The default lifetime is
  3600 seconds; the value used in production has not been verified.
- Per-client token lifetimes are not supported.
- A token with an empty scope can be issued by the current code. That receiving Studios
  answer `403` is expected from Identity Contract v1 but not yet verified by test.
- `knowledge:read` and `security:read` apply at route level. Limiting what content a caller
  can read is the owning Studio's responsibility, and its enforcement is unverified.
- Identity Contract v1 sets no maximum token lifetime and no clock-skew leeway for `exp`/`iat`.
- Approving this ADR does not establish production readiness; signing key storage is unverified.
- Until the follow-up change, ADR-005, the contract and the indexes still point to ADR-006.

## Mitigations

- The pre-production conditions are listed in the Decision so they are not lost.
- The follow-up change updates references and marks ADR-006 Superseded.
- Optional future work: overlapping secret rotation; rejecting empty-scope requests at
  issuance with regression tests; token identifiers and revocation if client privileges grow
  beyond read-only; per-client token lifetimes.

## Alternatives Considered

Options B and C above were rejected.

## References

- [Identity Contract v1](../standards/identity-contract.md)
- [ADR-005: Adopt Identity Contract v1 as the platform JWT standard](005-identity-contract-v1.md)
- [ADR-006: Nova M2M service tokens](006-nova-m2m-service-tokens.md)

---

*Decided: 2026-10-30*
*Author: niphan1000-cyber1000*
