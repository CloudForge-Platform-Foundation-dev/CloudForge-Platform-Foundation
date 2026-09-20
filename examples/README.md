# Examples

> Sample implementations and reference architectures for teams building new Studios on the CloudForge Platform.

---

## Purpose

This folder holds minimal, working reference implementations that demonstrate how a Studio should
integrate with the Foundation contract (auth pattern, schemas, governance gate, standard files).

It is **not** a place for full Studio source code — full Studios live in their own repositories
(see [MASTER_INDEX.md](../MASTER_INDEX.md) → Repository Structure).

## Planned Contents

| Example | Status | Description |
|---|---|---|
| `minimal-studio/` | 🔄 Planned | Smallest possible repo that passes `foundation-validation` (all standard files, no business logic) |
| `auth-integration/` | 🔄 Planned | Reference `src/auth/` implementation matching `docs/security/security-baseline.md` |
| `schema-usage/` | 🔄 Planned | Example of extending a canonical schema (`entity`/`event`) for a Studio-specific use case |

## Contributing an Example

See [CONTRIBUTING.md](../CONTRIBUTING.md). Examples should be small, runnable, and kept in sync with the
current Foundation contract version (see [VERSION](../VERSION)).
