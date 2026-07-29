# Platform Components — CloudForge Platform Foundation

> เอกสารนี้นิยามองค์ประกอบ (component) แต่ละชิ้นของแพลตฟอร์มอย่างเป็นทางการ — ชื่อ, หน้าที่,
> input/output, ผู้ใช้งาน, และสถานะปัจจุบัน ใช้เป็นจุดอ้างอิงกลางเวลาแอปใดแอปหนึ่งต้องคุยกับ
> อีกแอป จะได้รู้ว่าต้องคาดหวังอะไรจากกัน

---

## 1. App 1 — Dynamic Ingest AI

| หัวข้อ | รายละเอียด |
|---|---|
| **หน้าที่หลัก** | สกัดข้อมูลจากไฟล์ดิบ (PDF, ไฟล์สแกน, ฟอร์มกระดาษที่ถ่ายรูป) ให้เป็นข้อมูลโครงสร้าง |
| **Input** | ไฟล์ดิบของลูกค้า แบ่งเป็น 4 เฟส: นักเรียนปัจจุบัน / ครู-หอพัก / การเงิน / ข้อมูลย้อนหลัง |
| **Output** | ข้อมูลโครงสร้าง (structured record) เขียนลง `extracted_data` ใน Firestore |
| **ผู้ใช้งาน** | ทีม implement (ตอนตั้งค่าระบบให้ลูกค้าใหม่) |
| **สถานะ** | ตรวจสอบเสร็จแล้ว มี 5 จุดที่ต้องระวังก่อนขายจริง (persist metrics จริง, ชี้แจง reversible tokenization ในสัญญา, ตรวจ dependency, retention period ต้อง config ได้, ทดสอบ PII edge case) |
| **เชื่อมต่อกับ** | ส่งข้อมูลต่อให้ App 2 วิเคราะห์ |

---

## 2. App 2 — Dynamic Insight AI

| หัวข้อ | รายละเอียด |
|---|---|
| **หน้าที่หลัก** | วิเคราะห์ข้อมูลที่ App 1 สกัดมา + บังคับใช้นโยบาย Security & Data Governance |
| **Input** | ข้อมูลจาก `extracted_data` |
| **Output** | ผลวิเคราะห์ + `analysis_audit_log` (บันทึกทุกการกระทำ) |
| **ผู้ใช้งาน** | ทีม implement, ทีมตรวจสอบความปลอดภัย |
| **Sub-components** | Prompt Injection Test, Cost Guard/Token Guardrails, PDPA Cascade Console, Secret Scanning, Audit Trail Log (filter ตาม phase/category/batch/confidence) |
| **สถานะ** | อยู่ระหว่างแก้ security bug — ดูรายละเอียดที่ `docs/security/` |
| **เชื่อมต่อกับ** | รับข้อมูลจาก App 1, ให้ App 3 อ่านสถานะแบบ read-only |

### รายการ bug ที่ยังไม่แก้ (อ้างอิงจาก Sprint ก่อนหน้า)
1. 🔴 `firestore.rules`: `allow read: if true` เปิด public บน `extracted_data` และ
   `analysis_audit_log` — ต้องแก้เป็น `if false`
2. 🔴 `server.ts`: ยังไม่ต่อ Firestore จริง (`recordsStore`/`auditLogsStore` เป็น
   in-memory array), ยังไม่มี Firebase Auth จริง (`getUserRole()` เชื่อ header ที่ปลอมได้)
3. 🟡 บั๊ก UI: ตัวเลข "Records" ที่หัวแอปผูกกับผลลัพธ์หลัง filter แทนที่จะโชว์จำนวนทั้งหมดจริง

---

## 3. App 3 — Dynamic Command Center

| หัวข้อ | รายละเอียด |
|---|---|
| **หน้าที่หลัก** | Orchestration layer มองภาพรวมทั้ง pipeline ตั้งแต่ pitch ขายจนถึงติดตามงานจริง |
| **Input** | สถานะจาก App 1 และ App 2 (อ่านอย่างเดียว) |
| **Output** | Dashboard ภาพรวมสำหรับทีมขาย/ลูกค้า, config เริ่มต้นสำหรับ tenant ใหม่ (จาก Setup Wizard) |
| **ผู้ใช้งาน** | ทีมขาย, ลูกค้า, ทีม implement |
| **Sub-components** | โหมด Demo (mock), โหมด Live (Firestore จริงของ tenant), Setup Wizard (ตั้งชื่อโปรเจกต์, mapping หมวดหมู่→เฟส, สร้าง Service Account/Firestore แยกต่อราย) |
| **สถานะ** | อยู่ในขั้นวางแนวคิด ยังไม่เริ่มสร้าง |
| **เชื่อมต่อกับ** | อ่านจาก App 1/2, ไม่เขียนข้ามเข้าไปใน scope ของแอปอื่นโดยตรง |

### สิ่งที่ยังไม่ตัดสินใจ
- ชื่อสุดท้าย: Dynamic Command Center vs Dynamic Control Tower
- ต่อ Firestore จริงตั้งแต่ต้นหรือ mock-only ก่อน
- ขอบเขตสิทธิ์ที่ลูกค้าเห็นได้ในโหมด Live (แค่สถานะ หรือเห็นข้อมูลดิบด้วย)

---

## 4. Data Layer — Firestore

| หัวข้อ | รายละเอียด |
|---|---|
| **หน้าที่** | เก็บข้อมูลจริงของแต่ละ tenant |
| **Collections หลัก** | `extracted_data`, `analysis_audit_log`, (จะเพิ่ม `governance_metrics` เมื่อ persist จริง) |
| **การเข้าถึง** | ผ่าน backend (Firebase Admin SDK) เท่านั้น ห้าม client เข้าถึงตรง |
| **Isolation** | แยกต่อ tenant (รูปแบบยังไม่ตัดสินใจสุดท้าย — ดู `ENTERPRISE_ARCHITECTURE.md` ข้อ 6) |

---

## 5. Identity Layer — Firebase Auth

| หัวข้อ | รายละเอียด |
|---|---|
| **หน้าที่** | ยืนยันตัวตนผู้ใช้และออก ID token ที่ backend ใช้ verify สิทธิ์ |
| **สถานะปัจจุบัน** | ยังไม่ถูกใช้จริงใน App 2 — `getUserRole()` ยังเชื่อ header ที่ client กำหนดเอง |
| **เป้าหมาย** | ทุก endpoint ที่แก้ไข/อ่านข้อมูลสำคัญต้อง verify ID token ก่อนเสมอ |

---

## 6. ตาราง Component Ownership สรุป

| Component | เจ้าของ (ทีม) | Repo |
|---|---|---|
| App 1 — Dynamic Ingest AI | ทีม implement | `dynamic-ingest-ai` |
| App 2 — Dynamic Insight AI | ทีม implement + security | `dynamic-insight-ai` |
| App 3 — Dynamic Command Center | ทีมขาย + ทีม implement | ยังไม่สร้าง repo |
| Platform Foundation (เอกสารนี้) | ทุกทีมร่วมกัน | `CloudForge-Platform-Foundation` |

การเปลี่ยนแปลงที่กระทบมากกว่า 1 component ต้องบันทึกเป็น ADR ใน `docs/adr/` ก่อนแก้จริง
ตามหลักการใน `PLATFORM_PRINCIPLES.md` ข้อ 7