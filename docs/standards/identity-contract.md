# CloudForge Identity Contract — v1

**Status:** Proposed (see [ADR-005](../adr/005-identity-contract-v1.md)) — implemented in `cloudforge-auth-core` (latest release tag `v1.1.8`); awaiting Foundation approval
**Owner:** Foundation
**Contract Version:** `identity-contract-v1`
**Applies to:** every Studio (Ingest, Knowledge, Nova, Security, and future Studios)

---

## 1. Purpose

Define **one shared standard** for the JWTs that all Studios use, so that Studio-to-Studio auth contract drift cannot happen again. The drift seen between Ingest and Knowledge was a `scopes` list versus a `scope` string.

This is a **Foundation-level contract**, not an implementation. `cloudforge-auth-core` implements it (see section 7).

**Non-goal:** this document does not tie CloudForge to any IdP vendor. Auth0, Keycloak, Cognito, a custom Identity Service and so on can all implement this contract, as long as they issue JWTs of the shape below.

---

## 2. JWT Claims Contract

Every JWT issued by the CloudForge Identity Service must carry the claims below. References: RFC 7519 (JWT), RFC 9068 (JWT Profile for OAuth 2.0 Access Tokens), RFC 8725 (JWT Best Current Practices), RFC 6749 section 3.3 (scope).

```json
{
  "sub": "user-or-service-id",
  "iss": "https://identity.cloudforge.internal",
  "aud": "cloudforge-platform",
  "exp": 1234567890,
  "iat": 1234563890,
  "scope": "ingest:read ingest:write knowledge:read"
}
```

| Claim   | Type   | Required | Notes |
|---------|--------|----------|-------|
| `sub`   | string | yes      | user id or service account id |
| `iss`   | string | yes      | must match the issuer configured in the Studio |
| `aud`   | string or array of strings | yes | the token passes when the audience the Studio expects is among these values (if an array) |
| `exp`   | number (unix timestamp) | yes | must be validated every time |
| `iat`   | number (unix timestamp) | yes | used to check token freshness |
| `scope` | **string, space-separated** | yes (see section 5 for the missing-claim case) | see section 3 |

**`scopes` (list/array) must not be used as the main field.** This was the original drift and must be closed for good. If an IdP natively emits a list, it must be normalised to a space-separated string in the Identity Service before the token is handed out. Individual Studios must not normalise it themselves.

**Implementation note (auth-core v1.1.x):** `Principal.aud` keeps only the first value when a token's `aud` is an array (the full value stays in `raw_claims`), and there is no clock-skew leeway when checking `exp`/`iat`. This document records actual behaviour; adding leeway will be a later minor release.

---

## 3. Scope Convention

Format: `{studio}:{permission}`

```
ingest:read
ingest:write
knowledge:read
knowledge:write
nova:read
nova:write
```

Rules:

- Every scope string is separated by **a single space**, never a comma.
- A new Studio must register its scope namespace in the Foundation registry (Appendix A) before using it, to prevent name collisions.
- Wildcard scopes (for example `ingest:*`) are not allowed in v1; they are not atomic enough for audit.
- Scope parsing must use the single shared implementation (`auth-core`); Studios must not implement their own.

**Note:** the list above is illustrative, not the registry. The registry is Appendix A and is kept at namespace level.

---

## 4. Signature & Algorithm

- Algorithm: **RS256** only (no `alg: none`, no HS256 for tokens that cross Studios).
- The public key comes from the Identity Service **JWKS endpoint** only.
  - Do not hardcode public keys in Studio code.
  - Cache the JWKS with a TTL (recommended at most 1 hour; the `auth-core` default is 300 seconds) and refresh when `kid` does not match.
- Every Studio must reject a token whose:
  - `alg` is not RS256;
  - `kid` is not found in the current JWKS.

---

## 5. Error Semantics (mandatory, not optional)

| Situation | HTTP status |
|---|---|
| No token | `401` |
| Token cannot be parsed / malformed | `401` |
| Invalid signature | `401` |
| `exp` expired | `401` |
| `iss` mismatch | `401` |
| `aud` mismatch | `401` |
| `alg` is not RS256 | `401` |
| `kid` not found in JWKS (JWKS endpoint answered normally) | `401` |
| A required claim is missing (`sub`, `iss`, `aud`, `exp`, `iat`) | `401` |
| `scope` is present but is not a string (for example a list or a number) | `401` |
| A `scopes` claim (deprecated) appears in the token, even if a valid `scope` is also present | `401` |
| The `scope` claim is missing entirely, or is `null` (not an empty string) | authenticated with empty scopes, so `403` at `require_scope` (see notes) |
| **The Identity Service JWKS endpoint is unreachable (network/timeout)** | **`503`** |
| Token is valid but the scope is insufficient (including `scope` as an empty string) | `403` |
| Token is valid and the scope is sufficient | pass |

**503 versus 401, and why they are separate:** `401` means "the token the client sent is not valid" (client side; fixed at the client or when the Identity Service issues the token). `503` means "we cannot reach the JWKS endpoint right now" (an upstream dependency failure, unrelated to the token the client sent). The client can retry on `503`; retrying with the same token on `401` is pointless.

**A missing `scope` claim (or `null`) is not `401`:** authentication (is the token valid?) is kept separate from authorization (does it grant permission?). A token with no `scope` at all still authenticates successfully but carries no scopes (`scopes = frozenset()`), so every `require_scope(...)` rejects it with `403`, with no way to bypass. Putting a complete `scope` claim into the token is the Identity Service's job at issuance, not the Studio's job at verification. A `scopes` list, by contrast, is a shape that directly violates this contract and must be rejected with `401`.

**Note on `scope: null`:** the rule "authenticated, empty scopes gives 403" applies **only to tokens that have fully authenticated** (signature, `alg`, `kid`, `exp`, `iss`, `aud` and all required claims pass). Tokens that are malformed, have a bad signature or lack a required claim are handled separately and always get `401` before scope parsing. Treating `null` as "missing" is the current behaviour of `cloudforge-auth-core` (a regression test locking it exists since `cloudforge-auth-core` v1.1.8). It is not a long-term decision. Changing it to `401` requires evidence from code and regression tests, and must go through the amendment process in section 6.

**Every endpoint that enforces auth must declare both `401` and `403` in its OpenAPI spec**, with no exceptions. This is a P0 gate rule (see section 8). `503` is optional in each endpoint's OpenAPI spec (not mandatory like `401`/`403`, because it is an infrastructure-level failure and not part of the normal auth flow), but recommended for clarity.

---

## 6. Versioning Scheme

The contract (this document) is versioned separately from any package version:

```
identity-contract-v1   → the current contract (this document)
identity-contract-v2   → breaking changes only (for example a changed claim shape,
                          a changed algorithm, a changed scope format)
```

A breaking change to the contract must:

1. come with a migration guide;
2. announce a deprecation window so every Studio can update in time;
3. pass Foundation review, with no auto-merge.

The contract version is **not tied 1:1** to the `cloudforge-auth-core` package version (the package can ship patch and minor releases more often without the contract changing; see section 7).

---

## 7. Relationship to `cloudforge-auth-core`

```
identity-contract-v1        ← spec, stable, hard to change
        │
        ▼
cloudforge-auth-core        ← implementation of the contract, semver
    ├── 1.x  → backward-compatible with contract v1
    │          (minor = new features, patch = bug/security fixes)
    └── 2.0  → breaking (follows contract v2 only)
        │
        ▼
Each Studio pins its own version   (recommended range: >=1.1.8,<2)
```

**Release status**

- `v1.1.7` — annotated tag pointing at commit `d2740025895549d435608a46f54301f17d45b156`. **Immutable: never move or overwrite it.** The code at this tag still reports its own version as `1.1.6` (`pyproject.toml`, `__version__`, README). It can be installed from the tag, but the package metadata shows 1.1.6.
- `v1.1.8` — released 2026-10-13 (PR #6): annotated tag pointing at commit `7d44dfa7814065286ee06dc5458607da93c483ab`. It makes the reported version match the tag and does minor cleanup (BOM, unused imports, a CI comment) **without changing** verification, scope parsing or HTTP semantics. CI passed in full (pytest on Python 3.10 and 3.11, plus gitleaks), so `>=1.1.8,<2` is the recommended range for Studios.

Policy:

- Each Studio **pins its own version**; syncing all Studios at once is not required.
- Dependabot/Renovate plus Foundation policy flag version drift (flagging, not forced auto-upgrade).
- `auth-core` implements only: JWT verification, JWKS fetch/cache, scope parse/check, `get_current_user()` and `require_scope()`. It contains no Studio business logic.

Adoption status per Studio is in Appendix B.

---

## 8. Foundation Gate Rule

The Foundation gate (see [ADR-005](../adr/005-identity-contract-v1.md); to be implemented in a follow-up PR, starting in warning mode) is to flag a PR that contains:

- an OpenAPI endpoint that has an auth dependency but does not declare both `401` and `403`;
- a Studio that imports auth logic from anywhere other than `cloudforge-auth-core` (to stop copy-pasted auth code from coming back);
- `claims["scopes"]` (list form) in code. A simple grep-based rule in CI is enough to start.

**Note on the pattern for this rule:** it must be narrow and match only reads of the token's `scopes` claim. It must not match a `scopes` field in the request body of a token endpoint (for example `json={"scopes": [...]}` in a service-token client, or the request model of the Identity Service), because that is not a claim in a JWT and would be a false positive.

---

## 9. Not covered in v1 (kept for a later round)

- Refresh token flow
- Service-to-service (M2M) token issuance policy. Nova already uses client-credentials tokens from the Identity Service to call Knowledge with `knowledge:read`. The claims of those tokens follow this contract; the issuance policy is covered by [ADR-007](../adr/007-m2m-service-token-issuance-policy.md).
- Wildcard/hierarchical scopes
- Rate limiting tied to `sub`
- Clock-skew leeway for `exp`/`iat` (none today; can be added as a minor release without moving to v2)
- Keeping every `aud` value in `Principal` when a token's `aud` is an array

---

## Adoption checklist

Agreed approach: **One Contract → One Implementation → Many Studios**.

1. [x] Draft the contract
2. [ ] Foundation review and approval (see ADR-005)
3. [x] Implement `cloudforge-auth-core` to the contract (`v1.1.7`; `v1.1.8` released)
4. [x] Migrate Ingest to auth-core
5. [x] Migrate Knowledge to auth-core
6. [ ] Add the Foundation gate rule (section 8)
7. [x] Check/migrate Nova (auth-core binding; see the M2M note in section 9)
8. [x] Check/migrate Security Studio (pinned `v1.1.8`; scope registration is still to be confirmed, see Appendix A)

---

## Appendix A: Scope namespace registry

Registered at namespace level. Permission-level entries are added once the owning Studio confirms which scopes it enforces through `require_scope(...)`.

| Namespace | Owner Studio | Basis |
|---|---|---|
| `ingest` | Ingest | illustrative examples in section 3 (`ingest:read`, `ingest:write`) |
| `knowledge` | Knowledge | illustrative examples in section 3 (`knowledge:read`, `knowledge:write`) |
| `nova` | Nova | illustrative examples in section 3 (`nova:read`, `nova:write`) |
| `security` | Security | observed in the Identity Service allowlist (`security:read`, `security:write`) |

The scope `nova:query` also appears in the Identity Service allowlist. Whether Nova enforces it has not been confirmed. The allowlist itself lives in Identity Service code (`main.py`), not in a central registry.

---

## Appendix B: Adoption status per Studio (informational, as of 2026-10-17)

Checked from `origin/main` of each repository.

| Repository | `cloudforge-auth-core` | Notes |
|---|---|---|
| Ingest | pinned `v1.1.8` | `src/auth` wraps auth-core; no `jwt.decode` found in `src/` |
| Knowledge | pinned `v1.1.8` | no `jwt.decode` found in the repository; auth config passes issuer, audience and JWKS cache TTL to auth-core |
| Nova | pinned `v1.1.8` | `src/auth/dependencies.py` is an auth-core binding; no `jwt.` or `claims[` found in `src/` |
| Security | pinned `v1.1.8` | docstring describes a thin auth-core wrapper; no `jwt.decode` found on `origin/main` |
| `cloudforge-deployment-studio`, `cloudforge-e2e`, `cloudforge-infra-terraform` | not referenced | no match for `cloudforge-auth-core` or `jwt.decode` |

---

## Appendix C: Amendment history

Entries before 2026-10-19 date from the draft that lived outside Foundation.

- **2026-10-19** — Moved into Foundation as `docs/standards/identity-contract.md` (status Proposed, see ADR-005). Section 3 now points to a namespace-level registry (Appendix A). Section 7 adoption detail moved to Appendix B. Review notes about the Identity Service are not part of this document. No change to the claims shape, so the contract stays `identity-contract-v1`.
- **2026-10-17** — Recorded adoption status for every Studio; clarified that the gate pattern for `claims["scopes"]` must not match `scopes` in a request body; pointed the M2M note at a separate ADR. No change to the claims shape.
- **2026-10-14** — Recorded adoption status (section 7, checklist, section 9). No change to contract content.
- **2026-10-13** — Aligned the contract with the actual implementation: added the `401` rows for `alg`, `kid`, missing required claims, non-string `scope` and a `scopes` claim next to a valid `scope`; recorded that `scope: null` is treated as missing (`403`) once the token is fully authenticated; `aud` may be a string or an array; references changed to RFC 9068 / RFC 8725; recorded that there is no clock-skew leeway; replaced the non-existent `1.2.x` with the recommended range `>=1.1.8,<2` after `v1.1.8` was released; recorded the state of `v1.1.7` (immutable) and `v1.1.8`. No change to the claims shape.
- **2026-09-23** — Added `503` semantics (section 5) and clarified that a missing `scope` claim means authenticated with empty scopes (`403` at `require_scope`), not `401`. Added together with `cloudforge-auth-core` v1.1.0, which separates "JWKS endpoint unreachable" (`503`, upstream failure) from "invalid token" (`401`, client side). An additive amendment that does not touch the claims shape.
