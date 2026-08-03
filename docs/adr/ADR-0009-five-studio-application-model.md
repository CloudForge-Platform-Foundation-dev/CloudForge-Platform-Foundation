# ADR-0009: ปรับ Application Model จาก App 1/2/3 เป็น 5 Studio Application

## Title

ปรับโครงสร้างแอปพลิเคชันจาก App 1 / App 2 / App 3 ให้แมปตรงกับ AI Studio Layer 5 ตัว
(Ingest, Insight, Simulation, Deployment/Operations, Governance & Security)

## Status

**Accepted** — 2026-08-02
**Updated** — 2026-08-03 (แก้ไขรายละเอียดสถานะบั๊กความปลอดภัยให้ตรงกับผลตรวจสอบจริง)

## Context

`ENTERPRISE_ARCHITECTURE.md` และ `LOGICAL_ARCHITECTURE.md` นิยาม AI Studio Layer ไว้ 5 ตัว:
Ingest Studio, Insight Studio, Simulation Studio, Deployment Studio, Operations Studio

แต่ `PLATFORM_COMPONENTS.md` (เอกสารที่อธิบายของจริงที่ implement อยู่) ใช้ App 1/2/3 ซึ่ง:

- App 1 (Dynamic Ingest AI) แมปกับ Ingest Studio ได้ตรง
- App 2 (Dynamic Insight AI) แมปกับ Insight Studio ได้ตรง แต่ในทางปฏิบัติ App 2 แบกงาน
  Security/Governance (Prompt Injection Test, Secret Scanning, PDPA Console) ไว้ด้วย ซึ่งไม่ใช่
  ขอบเขตของ "Insight" ตามนิยามใน Enterprise Architecture
- App 3 (Dynamic Command Center) ไม่แมปกับ Studio ใดใน 5 ตัวเลย — เพราะหน้าที่จริงคือ
  Orchestration Dashboard / Setup Wizard ไม่ใช่ business capability ของ Studio

ปัญหานี้ถูกตรวจพบครั้งแรกใน `DEPLOYMENT_ARCHITECTURE.md` (Known Documentation Gaps) และยืนยันซ้ำ
โดยการตรวจสอบอิสระอีกครั้ง

## Problem Statement

เอกสาร Architecture ระดับ Enterprise/Logical กับเอกสารระดับ Component (ของจริง) พูดคนละภาษากัน
ทำให้:

1. ไม่มีทางรู้ว่า Studio ไหนใน Enterprise Architecture คือแอปตัวไหนในโลกจริง
2. งาน Security/Governance ถูกฝังไว้ใน App 2 แทนที่จะเป็น cross-cutting capability ตามหลัก
   "Security by Design" ที่เอกสารทุกฉบับประกาศไว้
3. App 3 ไม่มีที่ยืนในสถาปัตยกรรมภาพใหญ่เลย

## Decision

ปรับ Application Model เป็น 5 แอปธุรกิจ แมปกับ 5 Studio ตรงตัว:

| แอปพลิเคชัน | AI Studio ที่แมป | หน้าที่หลัก | สถานะโค้ดจริง (ณ วันที่เขียน ADR นี้) |
|---|---|---|---|
| dynamic-ingest-ai | Ingest Studio | สกัด/นำเข้าข้อมูล | ✅ มี repo จริง (เดิมคือ App 1) |
| dynamic-insight-ai | Insight Studio | วิเคราะห์ข้อมูล | ✅ มี repo จริง (เดิมคือ App 2 — **ตัด** ส่วน Security/Governance ออกตามข้อด้านล่าง) |
| dynamic-plan-ai | Simulation Studio | ออกแบบสถาปัตยกรรม/จำลองสถานการณ์/Roadmap | ❌ ยังไม่มี repo — เป็นแผนอนาคต |
| dynamic-ops-ai | Deployment / Operations Studio | Deploy, Monitoring | ❌ ยังไม่มี repo — เป็นแผนอนาคต |
| dynamic-guard-ai | Governance & Security Studio | Security Guardrails, PDPA, Audit Log | ❌ **ยังไม่มี repo — เป็นแผนอนาคตเท่านั้น** |

**Command Center (App 3 เดิม)** ไม่นับเป็น Studio ที่ 6 — จัดวางใหม่เป็น **"Platform Shell"** ใน
Experience Layer แทน (Dashboard ที่ครอบมองภาพรวมของทั้ง 5 Studio) เนื่องจากหน้าที่จริงคือ UI/Dashboard
ไม่มี business capability ของตัวเอง ตรงกับนิยาม Experience Layer ที่มีอยู่แล้วใน
`ENTERPRISE_ARCHITECTURE.md` (Web Portal / Dashboard)

### ⚠️ ข้อสำคัญเรื่องสถานะจริง — ห้ามเข้าใจผิด

ADR นี้เป็นการปรับ **สถาปัตยกรรมเป้าหมาย (target model)** เท่านั้น **ไม่ใช่การประกาศว่าแยกโค้ดเสร็จแล้ว**

- **`dynamic-guard-ai` ยังไม่มีโค้ดสักบรรทัด** — งาน Security/Governance ทั้งหมด
  **ยังคงอยู่ใน `dynamic-insight-ai` (App 2) เหมือนเดิมทุกประการ** จนกว่าจะมีการแยก repo จริง
- `dynamic-plan-ai` และ `dynamic-ops-ai` ก็เช่นกัน — เป็นช่อง (placeholder) ใน Roadmap เท่านั้น

## สถานะบั๊กความปลอดภัยใน App 2 (dynamic-insight-ai) — ตรวจสอบล่าสุด 2026-08-03

ADR ฉบับแรกระบุว่ามีบั๊กวิกฤต 2 จุดคือ `firestore.rules: allow read: if true` และ
`getUserRole()` ที่ไม่ verify token จริง การตรวจสอบโค้ดจริงเพิ่มเติมพบว่ารายละเอียดคลาดเคลื่อน
ไปบางส่วน สรุปสถานะจริงดังนี้:

### 1. `firestore.rules: allow read: if true`

- **มีการแก้ไขแล้ว** ในเวอร์ชัน `Dynamic-insight-ai-fixed`: ทุก collection เป็น fail-closed
  (`allow read: if false` และ default deny)
- **ข้อค้นพบสำคัญกว่านั้น**: ตรวจสอบด้วยการ grep ทั่วทั้งโปรเจกต์ (`firebase-admin`,
  `initializeApp`) ไม่พบการเชื่อมต่อ Firestore เลยแม้แต่จุดเดียว **ไม่มี Firebase project อยู่จริง**
  ข้อมูลทั้งหมดของแอปเก็บเป็น local JSON (`data/*.json`)
- **สรุป**: `firestore.rules` เป็นไฟล์เตรียมไว้เฉยๆ (dead config) ไม่เคยถูกบังคับใช้กับข้อมูลจริง
  ที่แอปนี้จัดการอยู่ ความเสี่ยงจากบั๊กนี้จึงไม่เคยมีผลกระทบจริงในทางปฏิบัติ

### 2. `getUserRole()` ไม่ verify token จริง

- **แก้ไปบางส่วนแล้ว** ในเวอร์ชัน fixed:
  - Fail-closed: ขอ role admin/analyst โดยไม่มี Bearer token ถูกต้อง → demote เป็น viewer ทันที
  - ปิดช่องโหว่ email spoofing (เดิมเชื่อ header `x-user-email` ตรงๆ ตอนนี้ดึงจาก token
    ที่ verify แล้วเท่านั้น)
  - Log unauthorized escalation attempt ทุกครั้ง
- **ยังไม่สมบูรณ์**:
  - ยังไม่ใช่ per-user authentication จริง — ใช้ shared secret token ต่อ role (ทุกคนที่เป็น
    analyst ใช้ token เดียวกัน) มี TODO ในโค้ดระบุว่าต้องย้ายไป Firebase Auth ID token
    verification แบบ per-user ตาม `SECURITY_MODEL.md` ข้อ 3.1
  - ถ้า token หลุด จะปลอมเป็นคนในกลุ่ม role นั้นได้ทุกคน และ audit log บันทึก email แบบ
    hardcode ตาม role ไม่ใช่ตัวคนจริง
  - ใช้ string comparison ธรรมดา (`.includes()`) ไม่ใช่ constant-time comparison
    (ความเสี่ยงต่ำ ไม่เร่งด่วน)

### 3. ความเสี่ยงตัวจริงที่ยัง live อยู่

ความเสี่ยงจริงคือ **REST API ผ่าน `getUserRole()`/`authorizeRole()` ใน `server.ts`**
ไม่ใช่ Firestore rules — priority งานที่เหลือควรโฟกัสจุดนี้แทน

### 4. สถานะ deployment

App นี้**ยังไม่เคย deploy ขึ้น production หรือ public hosting ใดๆ** (ไม่พบ config ของ
Firebase Hosting, Vercel, Railway, Render, Netlify หรือ Docker ในโปรเจกต์) ปัจจุบันรันบน
local เครื่องเดียว ผู้ใช้งานคนเดียว จึงยังไม่มีความเสี่ยงเร่งด่วนต่อผู้ใช้ภายนอก ณ ขณะนี้
อย่างไรก็ตาม ควรแก้ per-user authentication ให้เสร็จก่อน deploy ขึ้น production จริง

## Alternatives

1. **คงโครงสร้าง App 1/2/3 ไว้ตามเดิม** และแก้ Enterprise/Logical Architecture ให้เหลือ 3 Studio
   แทน — ถูกปฏิเสธ เพราะ 5 Studio Layer ถูกออกแบบไว้ก่อนแล้วในเอกสารหลายฉบับ การลดจำนวน Studio
   จะกระทบ Roadmap และงานเอกสารอื่นมากกว่า
2. **ให้ Command Center เป็น Studio ที่ 6** — ยังเปิดเป็นทางเลือกไว้ ถ้าในอนาคต Command Center
   มี business logic ของตัวเองเพิ่มขึ้น (ไม่ใช่แค่ dashboard) ควรทบทวน ADR นี้ใหม่

## Consequences

### สิ่งที่ต้องแก้ตามมา (เอกสาร)

- `PLATFORM_COMPONENTS.md` — อัปเดตตาราง Component Ownership และรายละเอียด App 2 ให้ตัด
  ขอบเขต Security ออก พร้อมหมายเหตุว่า guard-ai ยังไม่มีโค้ดจริง
- `ENTERPRISE_ARCHITECTURE.md` / `LOGICAL_ARCHITECTURE.md` — เพิ่ม Command Center เข้า
  Experience Layer, เพิ่มชื่อแอปจริง (dynamic-ingest-ai ฯลฯ) ต่อท้ายชื่อ Studio เพื่อให้ตามได้
- `ROADMAP.md` — เพิ่ม milestone สำหรับ dynamic-plan-ai, dynamic-ops-ai, dynamic-guard-ai
  อย่างชัดเจนว่ายังไม่เริ่ม
- `ADR_INDEX.md` — เพิ่มแถว ADR-0009 นี้เข้า index

### สิ่งที่ยังไม่ต้องแก้ (ยังไม่มีผลกระทบจริง)

- โค้ดของ `dynamic-insight-ai` — bug security เดิมยังต้องแก้ในที่เดิม ไม่ต้องรอย้าย repo ก่อน
- `firestore.rules` — ไม่ต้องเร่งแก้เพิ่ม เพราะไม่ถูกใช้งานจริง (แต่เวอร์ชัน fixed ที่แก้ไว้แล้ว
  ก็ปลอดภัยดี เก็บไว้ได้)

## Benefits

- App/Studio mapping ชัดเจน ตามได้ทั้งสองทาง (บน-ล่าง)
- แยกความรับผิดชอบ Security/Governance ออกจาก Insight ชัดเจนขึ้นในระยะยาว
- Command Center มีที่ยืนในสถาปัตยกรรมแล้ว ไม่ใช่ orphan component อีกต่อไป

## Risks

- ถ้าไม่ระบุสถานะ "ยังไม่มีโค้ด" ให้ชัดในทุกเอกสารที่แก้ตาม อาจทำให้ทีมเข้าใจผิดว่า Security
  bug ถูกแยกจัดการแล้ว ทั้งที่ยังฝังอยู่ใน App 2 เหมือนเดิม — **ต้องย้ำ status นี้ทุกจุดที่อ้างถึง
  dynamic-guard-ai**
- ถ้าไม่ระบุสถานะ per-user auth ที่ยังไม่สมบูรณ์ให้ชัด อาจทำให้เข้าใจผิดว่า security scope
  ของ App 2 "เสร็จสมบูรณ์แล้ว" ทั้งที่ยังมี known issue ค้างอยู่ (shared-secret-per-role)
- Command Center ในฐานะ Experience Layer อาจไม่ใช่คำตอบสุดท้าย ถ้า scope โตขึ้นในอนาคต

## References

- PLATFORM_COMPONENTS.md
- ENTERPRISE_ARCHITECTURE.md
- LOGICAL_ARCHITECTURE.md
- DEPLOYMENT_ARCHITECTURE.md (Known Documentation Gaps)
- CLOUDFORGE_CONSTITUTION.md ข้อ 8 (Architecture Decision Rule)
- SECURITY_MODEL.md ข้อ 3.1 (per-user authentication requirement)

---

End of ADR-0009
