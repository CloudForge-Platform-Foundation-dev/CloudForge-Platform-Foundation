# Canonical Data Model

> Standardized data definitions for interoperability across all Studios.

## Principles

1. **Single Source of Truth** — Define once, use everywhere
2. **Immutable Data** — Raw data never changes
3. **Versioned Schemas** — Changes are backward-compatible or version-bumped
4. **Extensible** — Studios can extend base schemas

## Base Schemas

### Entity

All domain entities extend the base entity schema:

```json
{
  "id": "uuid",
  "entityType": "string",
  "createdAt": "iso-timestamp",
  "updatedAt": "iso-timestamp",
  "createdBy": "uuid",
  "updatedBy": "uuid",
  "version": "integer",
  "metadata": "object",
  "tags": ["string"]
}
```

See: [schemas/canonical/entity.schema.json](../../schemas/canonical/entity.schema.json)

### Event

All domain events follow the base event schema:

```json
{
  "eventId": "uuid",
  "eventType": "Domain.Action",
  "source": "service-name",
  "timestamp": "iso-timestamp",
  "correlationId": "uuid",
  "causationId": "uuid",
  "payload": "object",
  "metadata": {
    "schemaVersion": "v1.0",
    "traceId": "string"
  }
}
```

See: [schemas/canonical/event.schema.json](../../schemas/canonical/event.schema.json)

## Extending Schemas

Studios can create domain-specific schemas that reference canonical schemas:

```json
{
  "$ref": "https://cloudforge.io/schemas/canonical/v1/entity.schema.json",
  "properties": {
    "customField": { "type": "string" }
  }
}
```

## Versioning

- Schemas are versioned via path: `schemas/canonical/v1/`, `v2/`
- Breaking changes require major version bump
- Studios must declare which schema version they use
