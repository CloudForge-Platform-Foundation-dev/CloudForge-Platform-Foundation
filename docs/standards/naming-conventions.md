# Naming Conventions

> Consistent naming across all CloudForge repositories and services.

## Repositories

```
cloudforge-{domain}-{type}
```

Examples:
- `cloudforge-ingest-studio`
- `cloudforge-security-service`
- `cloudforge-shared-lib`

## Branches

```
feature/{description}
fix/{description}
hotfix/{description}
release/v{major}.{minor}.{patch}
docs/{description}
```

Examples:
- `feature/user-authentication`
- `fix/memory-leak`
- `release/v1.2.0`

## Commits

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
{type}({scope}): {description}
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `security`

## Services

```
{domain}-{function}
```

Examples:
- `ingest-service`
- `nova-api`
- `security-scanner`

## Database

- Tables: `snake_case` plural (`user_profiles`)
- Columns: `snake_case` (`created_at`)
- Indexes: `idx_{table}_{column}`

## Environment Variables

```
{COMPONENT}_{PURPOSE}
```

Examples:
- `DATABASE_URL`
- `INGEST_API_KEY`
- `SECURITY_SCAN_TIMEOUT`
