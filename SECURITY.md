# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| v0.1.x  | ✅ Yes    |

## Reporting a Vulnerability

Please **DO NOT** open a public issue for security vulnerabilities.

Instead:
1. Email: security@cloudforge.example.com (replace with actual)
2. Or use GitHub Security Advisories

We will respond within 48 hours.

## Security Standards

All CloudForge repositories must implement:

- [ ] Authentication & Authorization
- [ ] Least Privilege Access
- [ ] Encryption in Transit (TLS 1.3+)
- [ ] Encryption at Rest
- [ ] Secrets Management (no hardcoded secrets)
- [ ] Dependency Scanning
- [ ] Static Code Analysis (SAST)
- [ ] Audit Logging
- [ ] Continuous Security Monitoring

## Security Review Process

Security reviews are mandatory for:
- New architectural patterns
- Changes to authentication/authorization
- Data model changes affecting PII
- New external dependencies

## Threat Model

See [docs/security/security-baseline.md](docs/security/security-baseline.md) for the platform threat model.
