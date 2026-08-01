# Deployment Architecture

Version: v0.1.0

Status: Draft

Owner: CloudForge Platform

Last Updated: 2026-08-01

---

# Overview

เอกสารนี้อธิบายว่า Component ต่างๆ ที่นิยามไว้ใน `PLATFORM_COMPONENTS.md` ถูก deploy จริงอย่างไรในปัจจุบัน
ต่างจาก `ENTERPRISE_ARCHITECTURE.md` และ `LOGICAL_ARCHITECTURE.md` ที่อธิบายสถาปัตยกรรมแบบ
technology-agnostic เอกสารนี้ผูกกับเทคโนโลยีจริงที่ใช้งานอยู่ตอนนี้โดยเฉพาะ

> **หมายเหตุสำคัญ:** Infrastructure Layer ใน `ENTERPRISE_ARCHITECTURE.md` ระบุเป้าหมายเป็น
> multi-cloud (AWS / Azure / GCP / Kubernetes / On-Prem) แต่ระบบจริงที่ implement อยู่ตอนนี้
> (App 1, App 2, App 3) ใช้ **Firebase / Firestore ล้วนๆ** เอกสารนี้จึงแบ่งเป็น 2 ส่วนชัดเจน:
> **"สถานะปัจจุบัน"** (ของจริง) และ **"เป้าหมายระยะยาว"** (ตามที่ Enterprise Architecture วางไว้)
> เพื่อไม่ให้ผู้อ่านเข้าใจผิดว่าระบบ multi-cloud พร้อมใช้งานแล้ว

---

# ส่วนที่ 1: สถานะปัจจุบัน (Current Deployment Reality)

## 1.1 Deployment Target

| รายการ | ค่าปัจจุบัน |
|---|---|
| Cloud Provider | Google Cloud (ผ่าน Firebase) |
| Database | Firestore |
| Authentication | Firebase Auth (นิยามไว้แล้ว แต่ App 2 ยังไม่ได้ใช้งานจริง — ดูหัวข้อ 1.4) |
| Hosting / Compute | ยังไม่ระบุชัดเจนในเอกสารต้นทาง (ต้องยืนยันกับทีม implement ว่า deploy backend ไว้ที่ไหน เช่น Cloud Functions, Cloud Run, หรืออื่นๆ) |
| Container / Orchestration | ไม่มี (ยังไม่ใช้ Kubernetes) |
| Multi-cloud | ไม่มี (ใช้ GCP เจ้าเดียว ผ่าน Firebase) |

---

## 1.2 Deployment Topology ต่อ Component

```text
                    +---------------------------+
                    |   Firebase Auth (Identity) |
                    |   สถานะ: นิยามแล้ว          |
                    |   แต่ App 2 ยังไม่ได้ต่อจริง |
                    +--------------+--------------+
                                   |
                                   v (ID token verification — ยังไม่ enforce)
+----------------+      +--------------------+      +----------------------+
|  App 1         | ---> |  App 2             | ---> |  App 3               |
|  Dynamic       |      |  Dynamic Insight AI |      |  Dynamic Command      |
|  Ingest AI     |      |  (analysis +        |      |  Center               |
|                |      |   governance)       |      |  (สถานะ: วางแนวคิด    |
|  เขียนเข้า      |      |  อ่าน/เขียน          |      |   ยังไม่เริ่มสร้าง)    |
|  extracted_data|      |  analysis_audit_log |      |  อ่าน App1/2 เท่านั้น  |
+-------+--------+      +---------+----------+      +----------------------+
        |                         |
        v                         v
   +---------------------------------------+
   |             Firestore                  |
   |  extracted_data                        |
   |  analysis_audit_log                    |
   |  (governance_metrics — ยังไม่ persist)  |
   +---------------------------------------+
```

App 1 และ App 2 เป็นแอปที่ deploy แล้ว (อยู่ในสถานะตรวจสอบ/แก้บั๊ก) ส่วน App 3 **ยังไม่มี repo และยังไม่ deploy**
(ตาม `PLATFORM_COMPONENTS.md` ข้อ 3)

---

## 1.3 Tenant Isolation Model — ⚠️ ยังไม่ตัดสินใจ

`PLATFORM_COMPONENTS.md` ส่วน Data Layer อ้างอิงว่ารูปแบบ isolation ต่อ tenant "ยังไม่ตัดสินใจสุดท้าย —
ดู `ENTERPRISE_ARCHITECTURE.md` ข้อ 6"

**พบปัญหา:** ไฟล์ `ENTERPRISE_ARCHITECTURE.md` เวอร์ชันปัจจุบัน **ไม่มีหัวข้อที่เป็นข้อ 6 หรือหัวข้อที่พูดถึง
tenant isolation เลย** — cross-reference นี้ชี้ไปยังเนื้อหาที่ยังไม่ถูกเขียน ต้องเลือกอย่างใดอย่างหนึ่ง:

- เพิ่มหัวข้อ Tenant Isolation ลงใน `ENTERPRISE_ARCHITECTURE.md` จริงๆ (แนะนำ) หรือ
- แก้ reference ใน `PLATFORM_COMPONENTS.md` ให้ชี้มาที่เอกสารนี้แทน เมื่อตัดสินใจ model แล้ว

ตัวเลือกที่ต้องตัดสินใจ (ยกมาจาก App 3 open questions ใน `PLATFORM_COMPONENTS.md`):

- **Firestore project แยกต่อ tenant** (ตามที่ Setup Wizard ของ App 3 ออกแบบไว้คร่าวๆ — สร้าง Service
  Account/Firestore แยกต่อราย)
- **Firestore project เดียว แยกด้วย field/collection prefix ต่อ tenant**

จนกว่าจะตัดสินใจ ห้ามถือว่า tenant isolation เป็นเรื่องที่ออกแบบเสร็จแล้ว

---

## 1.4 Deployment Blockers — ต้องแก้ก่อนขึ้น Production

รายการนี้ดึงมาจากบั๊กที่ยังไม่แก้ใน `PLATFORM_COMPONENTS.md` (App 2) ซึ่งกระทบ deployment โดยตรง:

| ลำดับ | บั๊ก | ผลกระทบต่อ Deployment |
|---|---|---|
| 1 🔴 | `firestore.rules` เปิด `allow read: if true` บน `extracted_data` และ `analysis_audit_log` | **ห้าม deploy ขึ้น production เด็ดขาด** จนกว่าจะแก้เป็น `if false` และผูก security rule กับ Firebase Auth จริง |
| 2 🔴 | `server.ts` ยังไม่ต่อ Firestore จริง (`recordsStore`/`auditLogsStore` เป็น in-memory array) | ข้อมูลหายทุกครั้งที่ restart instance — deploy แบบ multi-instance หรือ auto-scaling ไม่ได้จนกว่าจะแก้ |
| 3 🔴 | `getUserRole()` เชื่อ header ที่ client กำหนดเอง ไม่ verify ID token จริง | Authentication bypass ได้ทั้งหมด — เป็น blocker อันดับ 1 ก่อนเปิดใช้งานจริง |
| 4 🟡 | ตัวเลข "Records" ผูกกับผลลัพธ์หลัง filter | ไม่กระทบ deployment โดยตรง แต่ควรแก้ก่อนส่งมอบลูกค้า |

**สรุป:** ตามสถานะปัจจุบัน App 2 **ยังไม่พร้อม deploy ขึ้น production** เนื่องจากช่องโหว่ด้าน security
2 จุด (ข้อ 1 และ 3) เป็น critical blocker

---

## 1.5 Environments

ยังไม่มีเอกสารต้นทางไหนระบุ environment strategy (Dev / Staging / Prod) ของ App 1–3 อย่างเป็นทางการ
— เป็นช่องว่างที่ควรเพิ่มเมื่อ App 3 Setup Wizard เริ่มสร้างจริง เพราะ Setup Wizard คือจุดที่จะสร้าง
Firestore/Service Account แยกต่อ tenant (ตามที่ระบุใน `PLATFORM_COMPONENTS.md`)

---

## 1.6 CI/CD

ยังไม่มีการกำหนด CI/CD pipeline สำหรับ App 1–3 ในเอกสารต้นทางใดเลย เรื่องนี้อยู่ในขอบเขตของ
`ROADMAP.md` v0.8.0 (Developer Platform) และ v0.6.0 (Workflow Engine) ซึ่งยังไม่ถึงคิว — ปัจจุบันจึง
ถือว่าเป็น **manual deployment** จนกว่าจะมีการตัดสินใจเพิ่มเติม

---

# ส่วนที่ 2: เป้าหมายระยะยาว (Future Target — ตาม Enterprise Architecture)

ส่วนนี้สรุปจาก `ENTERPRISE_ARCHITECTURE.md` และ `LOGICAL_ARCHITECTURE.md` เป็นทิศทางระยะยาวเท่านั้น
**ยังไม่ใช่สถานะปัจจุบัน**

## 2.1 Infrastructure Layer เป้าหมาย

- Amazon Web Services
- Microsoft Azure
- Google Cloud Platform
- Kubernetes
- On-Premises

## 2.2 ช่องว่างระหว่างของจริงกับเป้าหมาย

| Enterprise Architecture เป้าหมาย | สถานะจริงตอนนี้ |
|---|---|
| Multi-cloud (AWS/Azure/GCP) | GCP เท่านั้น ผ่าน Firebase |
| Kubernetes / Container Orchestration | ไม่มี |
| AI Orchestration Layer (AI Gateway, Model Registry, Agent Router) | ยังไม่ implement — App 1–3 ยังเป็น monolithic app แยกกัน ไม่มี orchestration layer กลาง |
| Data Platform Layer (Relational DB, Data Lake, Message Queue) | มีแค่ Firestore (NoSQL) เดี่ยวๆ |

ช่องว่างนี้ไม่ใช่เรื่องผิดปกติสำหรับโปรเจกต์ระยะ v0.1.0 (Foundation) แต่ควรบันทึกไว้เพื่อไม่ให้ผู้อ่าน
เอกสาร Enterprise Architecture เข้าใจผิดว่าระบบ multi-cloud พร้อมใช้งานแล้ว

---

# Open Decisions (สรุปรวม)

- [ ] Tenant isolation model (Firestore แยก project ต่อ tenant vs. project เดียวแยก field) — ดู 1.3
- [ ] Hosting/Compute target ของ App 1 และ App 2 (Cloud Functions? Cloud Run? อื่นๆ) — ยังไม่ระบุในเอกสารต้นทาง
- [ ] Environment strategy (Dev/Staging/Prod) — ยังไม่มี
- [ ] CI/CD pipeline — ยังไม่มี
- [ ] ชื่อสุดท้ายของ App 3 (Dynamic Command Center vs Dynamic Control Tower) — ตาม `PLATFORM_COMPONENTS.md`

---

# Known Documentation Gaps

- `PLATFORM_COMPONENTS.md` อ้างอิง `ENTERPRISE_ARCHITECTURE.md ข้อ 6` เรื่อง tenant isolation แต่
  หัวข้อนั้นไม่มีอยู่จริงในไฟล์ปัจจุบัน — ต้องแก้ไขให้ตรงกัน (ดู 1.3)

---

# Related Documents

- CONTEXT_DIAGRAM.md
- ENTERPRISE_ARCHITECTURE.md
- LOGICAL_ARCHITECTURE.md
- PLATFORM_COMPONENTS.md
- ROADMAP.md