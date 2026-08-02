# Enterprise Architecture

Version: v0.1.0

Status: Draft

Owner: CloudForge Platform

Last Updated: 2026-08-02

---

# Overview

CloudForge Platform follows a layered enterprise architecture that separates responsibilities while enabling all CloudForge Studios to collaborate through a shared platform foundation.

Every Studio is independent in its business capability but shares common platform services, governance, security, identity, and enterprise knowledge.

---

# Architecture Goals

- Single Source of Truth
- Modular Platform
- AI-Native Architecture
- Documentation First
- Blueprint Driven Development
- Security by Design
- Governance by Design
- Cloud Agnostic
- API First
- Event Driven

---

# Enterprise Architecture Layers

```
+-------------------------------------------------------+
|                    End Users                           |
+-------------------------------------------------------+

+-------------------------------------------------------+
|              Experience Layer                          |
| Web Portal | Dashboard | API | CLI | Mobile           |
+-------------------------------------------------------+

+-------------------------------------------------------+
|                 AI Studio Layer                        |
| Ingest | Insight | Simulation | Deploy&Ops | Guard    |
+-------------------------------------------------------+

+-------------------------------------------------------+
|             Platform Services Layer                    |
| IAM | Workflow | Notification | Audit | API Gateway   |
+-------------------------------------------------------+

+-------------------------------------------------------+
|           Enterprise Knowledge Layer                  |
| Knowledge Repository | Metadata | Search | Context    |
+-------------------------------------------------------+

+-------------------------------------------------------+
|                Data Platform Layer                     |
| Database | Object Storage | Cache | Queue | Index     |
+-------------------------------------------------------+

+-------------------------------------------------------+
|            Infrastructure Layer                        |
| AWS | Azure | GCP | Kubernetes | On-Prem              |
+-------------------------------------------------------+
```

---

# Experience Layer

Provides interfaces for users to interact with the platform.

Components

- Web Application
- Dashboard
- REST API
- GraphQL API
- CLI
- Mobile Support
- **Dynamic Command Center (Platform Shell)** — overview dashboard ที่ครอบมองภาพรวมของทั้ง 5
  Studio ด้านล่าง ไม่ใช่ Studio แยก (ดูเหตุผลที่ `docs/adr/ADR-0009-five-studio-application-model.md`)

---

# AI Studio Layer

Provides business capabilities through specialized AI Studios.

> **หมายเหตุ (ADR-0009):** รายชื่อ Studio ด้านล่างถูกปรับให้ตรงกับ Application Model จริง — รวม
> Deployment กับ Operations เป็น Studio เดียว และแยก Governance & Security ออกมาเป็น Studio ที่ 5
> (เดิมเคยฝังอยู่เป็น bullet ใต้ Operations) ชื่อ repo จริง (หรือที่ยังไม่มี repo) กำกับไว้ในวงเล็บ

CloudForge Ingest Studio (`dynamic-ingest-ai` — ✅ มี repo จริง)

- Data Collection
- Classification
- Metadata Extraction

CloudForge Insight Studio (`dynamic-insight-ai` — ✅ มี repo จริง)

- Requirement Analysis
- Architecture Design
- Gap Analysis
- Roadmap
- Risk Analysis

CloudForge Simulation Studio (`dynamic-plan-ai` — ❌ ยังไม่มี repo)

- Executive Dashboard
- Scenario Simulation
- Cost Comparison
- Visualization

CloudForge Deployment & Operations Studio (`dynamic-ops-ai` — ❌ ยังไม่มี repo)

- Terraform
- CloudFormation
- Bicep
- CI/CD
- Deployment Automation
- Monitoring
- Incident Management
- Performance
- Cost Optimization

CloudForge Governance & Security Studio (`dynamic-guard-ai` — ❌ ยังไม่มี repo — งาน Security
ตอนนี้ยังรันอยู่ใน `dynamic-insight-ai` จนกว่าจะแยก repo จริง ดู `PLATFORM_COMPONENTS.md` ข้อ 2)

- Security
- Compliance (PDPA)
- Guardrails
- Audit Logging

---

# Platform Services Layer

Shared services used by every Studio.

Core Services

- Identity Management
- API Gateway
- Workflow Engine
- Notification Service
- Audit Logging
- Configuration Service
- Secrets Management
- Licensing
- Telemetry

---

# Enterprise Knowledge Layer

Centralized knowledge shared across the platform.

Capabilities

- Knowledge Repository
- Document Storage
- Metadata Catalog
- Embedding Index
- Vector Search
- Enterprise Search
- Context Management

---

# Data Platform Layer

Responsible for enterprise data management.

Components

- Relational Database
- NoSQL Database
- Object Storage
- Search Engine
- Message Queue
- Cache
- Data Lake

---

# Infrastructure Layer

Supports multiple deployment models.

Supported Platforms

- Amazon Web Services
- Microsoft Azure
- Google Cloud Platform
- Kubernetes
- On-Premises

---

# Cross-Cutting Capabilities

Applied across every architecture layer.

- Authentication
- Authorization
- Audit Logging
- Encryption
- Monitoring
- Governance
- Compliance
- Observability
- Cost Management
- Backup
- Disaster Recovery

---

# Architecture Principles

- Platform First
- API First
- Documentation First
- AI Assisted
- Secure by Default
- Modular Design
- Loose Coupling
- High Cohesion
- Reusable Components
- Immutable Knowledge

---

# Related Documents

- PLATFORM_VISION.md
- PLATFORM_PRINCIPLES.md
- PLATFORM_COMPONENTS.md
- SECURITY_MODEL.md
- CANONICAL_DATA_MODEL.md
- GOVERNANCE_MODEL.md
- MASTER_INDEX.md
- ADR_INDEX.md