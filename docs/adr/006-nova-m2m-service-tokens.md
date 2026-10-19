# ADR-006: Nova M2M service tokens

## Status

📄 Proposed

## Context

Nova calls Knowledge with a client-credentials token obtained from the CloudForge Identity Service (`src/auth/service_token.py` in the Nova repository, recorded there as Decision 1b on 2026-10-03). The token carries the `knowledge:read` scope. This was implemented before Identity Contract v1 covered machine-to-machine (M2M) tokens: the contract lists M2M issuance policy as outside v1.

What is known, from read-only searches of the code (full files were not reviewed):

- The request to the token endpoint carries a `scopes` field in its JSON body.
- The Identity Service rejects bad issuance requests with messages such as "client_id and client_secret are required", "Invalid client credentials" and "Client is not allowed to request scopes".

## Problem Statement

- Foundation has no decision on whether M2M tokens follow the same contract as other tokens.
- A gate rule that flags reads of the token claim `scopes` could produce a false positive on the `scopes` field of the token-request body, which is not a JWT claim.
- The issuance policy is not written down anywhere in Foundation.

## Considered Options

### Option A: M2M tokens conform to the same claims contract (chosen)

**Pros:**
- One verification path in every Studio (`cloudforge-auth-core`).
- No extra token format to maintain.

**Cons:**
- Service accounts and users share one claims shape, so `sub` alone does not say which kind of caller it is.

### Option B: A separate token format for M2M

**Pros:**
- Could carry service-specific claims.

**Cons:**
- Two verification paths and two sets of rules to keep consistent.

### Option C: Leave M2M out of Foundation standards

**Pros:**
- No work now.

**Cons:**
- Leaves the ambiguity and the gate false-positive risk in place.

## Decision

Adopt Option A, and record explicitly what is not decided.

1. M2M tokens issued by the Identity Service are JWTs that conform to Identity Contract v1: claims, signature rules and error semantics. `sub` identifies the service account. A receiving Studio verifies them through the same path as any other token.
2. The name of the field used to request scopes in a token-endpoint request body belongs to the Identity Service API, not to the JWT claims contract. The gate rule for the claim `scopes` must not flag it.
3. **Not decided here.** Each of these needs evidence from the Identity Service or Nova code before it is written into the contract:
   - which clients may request which scopes;
   - how client secrets are stored, compared and rotated;
   - the lifetime of service tokens;
   - what happens when a client requests an empty scope (a token with `scope: ""`, or a rejection);
   - where the signing key comes from in production.
4. When those items are answered, either amend the contract (additive) or supersede this ADR.

## Consequences

### Positive

- The Nova to Knowledge path is covered by the same verification and the same error semantics as every other call.
- The gate rule for `claims["scopes"]` has a stated exclusion.

### Negative

- The issuance policy stays undocumented until the open items above are answered.
- A reader may assume that this ADR approves the current Nova implementation; it does not review it.

## Mitigations

- The open items are listed in the Decision so they are not lost.
- The follow-up gate rule includes a test that a request body containing `scopes` is not flagged.

## Alternatives Considered

Options B and C above were rejected.

## References

- [Identity Contract v1](../standards/identity-contract.md), sections 8 and 9
- [ADR-005: Adopt Identity Contract v1 as the platform JWT standard](005-identity-contract-v1.md)

---

*Decided: (set when the status changes to Approved)*
*Author: (maintainer to fill in)*
