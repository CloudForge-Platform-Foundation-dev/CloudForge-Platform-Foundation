# ADR-002: JSON Schema as Canonical Data Model Format

## Status

✅ Approved

## Context

CloudForge requires a canonical data model to ensure interoperability between all Studios. We need a machine-readable format that can be validated at build time.

## Problem Statement

Choose a schema definition format that is:
- Widely supported
- Language agnostic
- Validatable in CI/CD
- Human readable
- Supports evolution/versioning

## Considered Options

### Option A: JSON Schema (Selected)

**Pros:**
- Native support in most languages
- Extensive tooling (validation, documentation generation)
- Versioned via URI references
- Easy to diff in PRs
- Supported by OpenAPI

**Cons:**
- Verbose for complex types
- No native enum validation for some edge cases

### Option B: Protocol Buffers (Protobuf)

**Pros:**
- Compact binary serialization
- Strong typing
- Code generation

**Cons:**
- Requires protobuf compiler
- Less human-readable
- Harder to diff in PRs
- Ties us to gRPC ecosystem

### Option C: Avro

**Pros:**
- Schema evolution support
- Compact

**Cons:**
- Primarily for data streaming
- Less general-purpose
- Smaller tooling ecosystem

### Option D: TypeScript Interfaces

**Pros:**
- Developer-friendly

**Cons:**
- Not language agnostic
- No runtime validation without extra libraries

## Decision

Use **JSON Schema** as the canonical data model format.

All canonical schemas live in `schemas/canonical/` and follow naming convention: `{domain}.{entity}.schema.json`.

## Consequences

### Positive
- Studios can validate payloads in any language
- Schemas can be referenced from OpenAPI specs
- Easy to review changes in PRs
- Supports `$ref` for modular schema composition

### Negative
- Need to maintain schema-to-code mappings
- Some complex validations require custom keywords

## Mitigations

1. Provide code generation templates for common languages
2. Use `schemas/canonical/README.md` to document extension patterns
3. Version schemas via path: `schemas/canonical/v1/`, `schemas/canonical/v2/`

## References

- [schemas/canonical/entity.schema.json](../../schemas/canonical/entity.schema.json)
- [schemas/canonical/event.schema.json](../../schemas/canonical/event.schema.json)
- [docs/data-model/canonical-data-model.md](../data-model/canonical-data-model.md)

---

*Decided: 2026-08-10*
*Author: CloudForge Architecture Board*
