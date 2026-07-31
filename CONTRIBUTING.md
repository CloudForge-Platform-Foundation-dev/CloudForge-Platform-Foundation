# Contributing to CloudForge Platform Foundation

> Repository: CloudForge-Platform-Foundation
>
> Document Type: Development Contribution Guide
>
> Version: v0.1.0
>
> Status: Active
>
> Last Updated: 2026-07-30

---

# 1. Introduction

CloudForge Platform Foundation เป็น Enterprise AI Platform
ที่พัฒนาแบบ Repository-Based Development

ทุก Contribution ต้องปฏิบัติตามมาตรฐานของ CloudForge Constitution

เป้าหมายคือ

- Maintain Architecture Consistency
- Preserve Documentation Quality
- Ensure Security
- Enable Enterprise Scale Development

---

# 2. Development Philosophy

CloudForge ใช้แนวทาง

## Blueprint Driven Development

ทุก Feature ต้องเริ่มจาก

```
Requirement

↓

Architecture Design

↓

ADR (ถ้ามี)

↓

Implementation

↓

Validation

↓

Release
```

---

# 3. Repository Rules

Repository เป็น Single Source of Truth

Contributor ต้อง

- อ่าน Documentation ก่อนแก้ไข
- ตรวจสอบ Architecture ก่อนเพิ่ม Feature
- Update Index เมื่อเพิ่ม Document
- Update Changelog เมื่อมี Change

---

# 4. Branch Strategy

CloudForge ใช้ Git Flow Concept

## Main Branch

```
main
```

ใช้สำหรับ

- Stable Release
- Production Version

---

## Development Branch

```
develop
```

ใช้สำหรับ

- Integration
- Feature Testing

---

## Feature Branch

รูปแบบ

```
feature/<feature-name>
```

ตัวอย่าง

```
feature/ai-gateway

feature/knowledge-repository
```

---

## Bug Fix Branch

รูปแบบ

```
fix/<issue-name>
```

ตัวอย่าง

```
fix/cache-validation
```

---

## Documentation Branch

รูปแบบ

```
docs/<document-name>
```

ตัวอย่าง

```
docs/update-roadmap
```

---

# 5. Commit Convention

CloudForge ใช้ Conventional Commit

รูปแบบ

```
type(scope): description
```

---

## Commit Types

### Feature

```
feat:
```

ตัวอย่าง

```
feat(agent): add agent registry model
```

---

### Bug Fix

```
fix:
```

ตัวอย่าง

```
fix(api): correct authentication flow
```

---

### Documentation

```
docs:
```

ตัวอย่าง

```
docs: update architecture blueprint
```

---

### Refactoring

```
refactor:
```

ตัวอย่าง

```
refactor(platform): improve service structure
```

---

### Security

```
security:
```

ตัวอย่าง

```
security: update secret management policy
```

---

# 6. Pull Request Rules

ทุก Pull Request ต้องมี

## Description

อธิบาย

- เปลี่ยนอะไร
- ทำไมต้องเปลี่ยน
- Impact

---

## Checklist

ก่อน Merge ต้องตรวจสอบ

- [ ] Documentation Updated
- [ ] Test Completed
- [ ] Version Updated (ถ้าจำเป็น)
- [ ] Changelog Updated
- [ ] ADR Created (ถ้าจำเป็น)
- [ ] Security Reviewed

---

# 7. Documentation Rules

Document ใหม่ต้องมี Metadata

ตัวอย่าง

```
Title

Repository

Version

Status

Owner

Last Updated
```

---

# 8. Architecture Change Rules

ถ้าเปลี่ยน

- Architecture
- Data Model
- Security Model
- AI Design
- Platform Component

ต้องสร้าง ADR

---

# 9. Code Quality Rules

Code ต้อง

- อ่านง่าย
- Maintainable
- Tested
- Documented
- Secure

ห้าม

- Hardcode Secret
- Commit Password
- Commit API Key
- Ignore Security Warning

---

# 10. Security Contribution

Contributor ต้องปฏิบัติตาม

- Security by Design
- Least Privilege
- Zero Trust Principle
- Data Protection

---

# 11. Review Process

Flow

```
Contributor

↓

Pull Request

↓

Code Review

↓

Architecture Review

↓

Security Review

↓

Merge

```

---

# 12. Release Contribution

Release ต้องประกอบด้วย

- Version Update
- CHANGELOG Update
- Documentation Update
- Validation Report
- Git Tag
- Release Package

---

# 13. Questions

หากไม่แน่ใจเกี่ยวกับ

- Architecture
- Design
- Security
- Implementation

ให้สร้าง Discussion หรือ ADR ก่อนเริ่ม Development

---

# Final Rule

ทุก Contribution ต้องทำให้ CloudForge

- Stable
- Secure
- Maintainable
- Enterprise Ready

มากขึ้น

---

End of Contributing Guide
