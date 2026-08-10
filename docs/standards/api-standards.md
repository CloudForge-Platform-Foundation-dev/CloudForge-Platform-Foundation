# API Standards

> Design guidelines for all CloudForge APIs.

## RESTful Design

- Use nouns for resources: `/users`, `/projects`
- Use HTTP methods correctly:
  - GET: Read
  - POST: Create
  - PUT: Full update
  - PATCH: Partial update
  - DELETE: Remove

## URL Structure

```
/api/v1/{resource}
/api/v1/{resource}/{id}
/api/v1/{resource}/{id}/{sub-resource}
```

## Request / Response

- Content-Type: `application/json`
- Use camelCase for JSON keys
- Include `requestId` in every response for tracing

## Error Handling

```json
{
  "error": "INVALID_REQUEST",
  "message": "The request payload is invalid",
  "requestId": "550e8400-e29b-41d4-a716-446655440000",
  "details": [
    {
      "field": "email",
      "issue": "Must be a valid email address"
    }
  ]
}
```

## Pagination

```json
{
  "data": [...],
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "totalItems": 150,
    "totalPages": 8
  }
}
```

## Versioning

- URL path versioning: `/api/v1/`, `/api/v2/`
- Deprecation: 6-month notice before removal
- Sunset header for deprecated endpoints

## Security

- Authentication: Bearer JWT
- Rate limiting: 1000 requests/minute per client
- Input validation: Strict schema validation
- Output encoding: Prevent injection attacks

## OpenAPI

All APIs must have an OpenAPI 3.0+ specification.
Use the template at `schemas/api/api-spec-template.yaml`.
