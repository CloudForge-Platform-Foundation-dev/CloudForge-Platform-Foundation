# Security Baseline

> Minimum security requirements for all CloudForge repositories and services.

## Authentication & Authorization

- All services must authenticate requests
- Use OAuth 2.0 / OIDC for user authentication
- Use mTLS or API keys for service-to-service
- Implement RBAC with least privilege

## Data Protection

- Encryption in transit: TLS 1.3 minimum
- Encryption at rest: AES-256
- Secrets: Use dedicated secrets manager (never hardcode)
- PII: Mask in logs, encrypt in storage

## Audit & Logging

- All access must be logged
- Logs must include: who, what, when, where, result
- Retention: Minimum 1 year for security logs
- Forward to centralized SIEM

## Dependency Management

- Scan all dependencies for vulnerabilities
- Update critical vulnerabilities within 7 days
- Maintain SBOM for all services

## Infrastructure

- No public access to databases
- Network segmentation between Studios
- Container images: No root user, minimal base images
- Use specific image tags (never `latest`)

## Compliance

- SOC 2 Type II
- ISO 27001
- GDPR (where applicable)
- Regular penetration testing

## Threat Model

[To be completed — see ADR for threat modeling approach.]

## Incident Response

1. Detect — Automated monitoring and alerting
2. Triage — Classify severity (P1-P4)
3. Contain — Isolate affected systems
4. Investigate — Root cause analysis
5. Recover — Restore normal operations
6. Document — Post-incident review
