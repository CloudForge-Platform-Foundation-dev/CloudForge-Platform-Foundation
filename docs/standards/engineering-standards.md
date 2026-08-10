# Engineering Standards

> Coding, documentation, and development standards for all CloudForge Studios.

## Version Control

- **Git Flow**: `main`, `develop`, `feature/*`, `fix/*`, `release/*`, `hotfix/*`
- **Commit Messages**: Conventional Commits
  ```
  feat(ingest): add CSV parser
  fix(api): resolve null pointer
  docs: update architecture diagram
  security(auth): enforce MFA
  ```
- **Branch Protection**: Require PR + 2 approvals + CI pass

## Code Quality

- **Test Coverage**: Minimum 80%
- **Static Analysis**: Required in CI
- **Code Review**: All changes reviewed by 2+ engineers
- **Documentation**: Every public API must be documented

## CI/CD

- **Build**: Must pass on every PR
- **Test**: Unit, integration, and security tests
- **Deploy**: Automated to staging; manual approval for production
- **Rollback**: Must be possible within 5 minutes

## Documentation

- README.md in every repository
- Architecture Decision Records for significant changes
- API documentation (OpenAPI)
- Runbooks for operational procedures

## Technology Choices

Studios may choose their tech stack within these guidelines:
- Backend: Node.js, Python, Go, Java (LTS versions only)
- Frontend: React, Vue, Angular
- Database: PostgreSQL, MongoDB, Redis (managed preferred)
- Message Queue: Kafka, RabbitMQ, AWS SQS
- Container: Docker + Kubernetes

## Performance

- API response time: P95 < 500ms
- Database query time: P95 < 100ms
- Error rate: < 0.1%
- Availability: 99.9% minimum
