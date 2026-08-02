# CloudForge Platform Foundation

# Architecture Decision Record Index (ADR Index)

> Repository: CloudForge-Platform-Foundation
>
> Status: Active
>
> Current Version: v0.1.0
>
> Last Updated: 2026-08-02

---

# Purpose

Architecture Decision Records (ADR) ใช้สำหรับบันทึกการตัดสินใจด้านสถาปัตยกรรมของ CloudForge Platform Foundation

ทุกการตัดสินใจที่มีผลต่อ

- Platform Architecture
- Security
- Data Model
- Knowledge Repository
- AI Platform
- API
- Governance
- Enterprise Standards

จะต้องมี ADR รองรับเสมอ

---

# ADR Status

ADR สามารถมีสถานะดังนี้

| Status | Description |
|----------|-------------|
| Proposed | อยู่ระหว่างเสนอ |
| Accepted | อนุมัติแล้ว |
| Superseded | ถูกแทนที่ |
| Deprecated | เลิกใช้ |
| Rejected | ปฏิเสธ |

---

# ADR Naming Convention

> **หมายเหตุ (2026-08-02):** เดิม `GOVERNANCE_MODEL.md` (Sprint 4) มีคิว ADR ของตัวเองแยกต่างหาก
> ใช้เลข 3 หลัก (`ADR-001` ถึง `ADR-006`) คนละระบบกับที่นี่ (4 หลัก) — **รวมเข้าด้วยกันแล้ว**
> เป็นเลขทางการ 4 หลักสายเดียว (ADR-0010 ถึง ADR-0015) ดูตาราง mapping ที่
> `GOVERNANCE_MODEL.md` ข้อ 3.1 (อัปเดตแล้ว) ห้ามใช้เลข 3 หลักอีกต่อไปทั้ง repo

```
ADR-0001-title.md
ADR-0002-title.md
ADR-0003-title.md
```

ตัวอย่าง

```
ADR-0001-blueprint-driven-development.md

ADR-0002-single-source-of-truth.md

ADR-0003-immutable-knowledge-repository.md
```

---

# ADR Template

ทุก ADR ต้องมี

- Title
- Status
- Context
- Problem Statement
- Decision
- Alternatives
- Consequences
- Benefits
- Risks
- References

---

# ADR Index

| ADR | Title | Status | Version |
|------|-------|---------|----------|
| ADR-0001 | Blueprint Driven Development | Planned | v0.1.0 |
| ADR-0002 | Single Source of Truth | Planned | v0.1.0 |
| ADR-0003 | Immutable Knowledge Repository | Planned | v0.1.0 |
| ADR-0004 | Enterprise Governance | Planned | v0.1.0 |
| ADR-0005 | AI Gateway Architecture | Planned | v0.2.0 |
| ADR-0006 | Knowledge Repository Architecture | Planned | v0.3.0 |
| ADR-0007 | Agent Runtime Architecture | Planned | v0.5.0 |
| ADR-0008 | Security Architecture | Planned | v0.7.0 |
| ADR-0009 | Five-Studio Application Model | Accepted | v0.1.0 |
| ADR-0010 | Tenant Isolation Model | Proposed | v0.1.0 |
| ADR-0011 | App 3 (Platform Shell) Firestore Connection Timing — Mock-first vs Real from Start | Proposed | v0.1.0 |
| ADR-0012 | Inter-App API Pattern — REST vs Firestore Listener | Proposed | v0.1.0 |
| ADR-0013 | `governance_metrics` Persistence Start Timing | Proposed | v0.1.0 |
| ADR-0014 | Final Name of App 3 (Dynamic Command Center vs Dynamic Control Tower) | Proposed | v0.1.0 |
| ADR-0015 | Customer Data Visibility Scope in Live Mode | Proposed | v0.1.0 |

---

# ADR Workflow

```
Idea

↓

Discussion

↓

Proposal

↓

Review

↓

Approval

↓

ADR Created

↓

Implementation

↓

Release
```

---

# ADR Storage

```
docs/

└── adr/

    ├── ADR-0001-blueprint-driven-development.md

    ├── ADR-0002-single-source-of-truth.md

    ├── ADR-0003-immutable-knowledge-repository.md
```

---

# Governance Rules

- ทุก Breaking Change ต้องมี ADR
- ทุก Architectural Change ต้องมี ADR
- ทุก Security Design ต้องมี ADR
- ทุก Data Model Change ต้องมี ADR
- ทุก AI Architecture Change ต้องมี ADR
- ADR ต้องได้รับการ Review ก่อน Merge
- ADR ต้องอ้างอิงใน Release หากเกี่ยวข้อง

---

# Future ADR Topics

Planned

- Multi-Tenant Architecture
- Zero Trust Security
- Event-Driven Architecture
- Domain Driven Design
- AI Gateway Routing
- Model Registry
- Prompt Registry
- Workflow Engine
- Plugin Architecture
- Agent Marketplace
- Multi-Cloud Deployment
- Kubernetes Strategy
- Observability Framework

---

# References

- Master Index
- Roadmap
- Changelog
- Architecture Documentation
- Governance Documentation

---

End of ADR Index
