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

> **หมายเหตุ (ADR-0009):** เดิม component นี้แบกงาน Security/Governance ไว้ด้วย ตาม ADR-0009
> งานส่วนนั้นถูกกำหนดให้ย้ายไป `dynamic-guard-ai` (Governance & Security Studio) ในระยะยาว
> **แต่ ณ วันที่เขียนเอกสารนี้ `dynamic-guard-ai` ยังไม่มี repo ยังไม่มีโค้ดสักบรรทัด**
> ดังนั้นรายละเอียดและบั๊กด้าน Security ด้านล่างนี้ **ยังคงเป็นของจริงใน `dynamic-insight-ai`
> เหมือนเดิมทุกประการ** จนกว่าจะมีการแยก repo จริง ห้ามเข้าใจว่าปัญหาถูกย้ายไปจัดการที่อื่นแล้ว

| หัวข้อ | รายละเอียด |
|---|---|
| **หน้าที่หลัก** | วิเคราะห์ข้อมูลที่ App 1 สกัดมา *(ขอบเขต Security & Data Governance เดิมกำลังทยอยย้ายไป `dynamic-guard-ai` ตาม ADR-0009 — ดูหมายเหตุด้านบน)* |
| **Input** | ข้อมูลจากขั้นตอนสกัดของ App 1 — ปัจจุบันเก็บเป็น local JSON (`data/*.json`) บนเครื่อง ไม่ใช่ Firestore (ดูหมายเหตุในข้อ 4) |
| **Output** | ผลวิเคราะห์ + audit log (บันทึกทุกการกระทำ) |
| **ผู้ใช้งาน** | ทีม implement, ทีมตรวจสอบความปลอดภัย |
| **Sub-components** | Prompt Injection Test, Cost Guard/Token Guardrails, PDPA Cascade Console, Secret Scanning, Audit Trail Log (filter ตาม phase/category/batch/confidence) — *sub-components เหล่านี้คือของที่จะย้ายไป `dynamic-guard-ai` ในอนาคต ตอนนี้ยังรันอยู่ใน repo นี้* |
| **สถานะ** | ตรวจสอบและแก้ไข security bug รอบแรกเสร็จแล้ว (เวอร์ชัน fixed) ยังมี known issue ค้างอยู่ 1 จุด — ดูรายละเอียดด้านล่าง ยังไม่เคย deploy ขึ้น production จริง (รันบน local คนเดียว) |
| **เชื่อมต่อกับ** | รับข้อมูลจาก App 1, ให้ App 3 อ่านสถานะแบบ read-only |

### สถานะ bug ความปลอดภัย — ตรวจสอบล่าสุด 2026-08-03

1. ✅ **`firestore.rules`: `allow read: if true`** — แก้เป็น fail-closed แล้วในเวอร์ชัน fixed
   (`allow read: if false` ทุก collection ที่สำคัญ + default deny) **และตรวจยืนยันเพิ่มเติมว่า
   โปรเจกต์นี้ไม่มีการเชื่อมต่อ Firestore เลยแม้แต่จุดเดียว** (ไม่พบ `firebase-admin` หรือ
   `initializeApp` ทั่วทั้งโปรเจกต์) ไม่มี Firebase project อยู่จริง — ไฟล์ `firestore.rules`
   จึงเป็นไฟล์เตรียมไว้เฉยๆ ไม่เคยถูกบังคับใช้กับข้อมูลจริง
2. 🟡 **`getUserRole()` ไม่ verify token จริง** — แก้ไปบางส่วนแล้วในเวอร์ชัน fixed: fail-closed
   เมื่อไม่มี token ที่ถูกต้อง, ปิดช่องโหว่ header spoofing (ไม่เชื่อ `x-user-email` ตรงๆ อีกต่อไป
   ดึงจาก token ที่ verify แล้วเท่านั้น), log ความพยายาม escalate สิทธิ์ผิดปกติทุกครั้ง
   **แต่ยังไม่สมบูรณ์** — ยังใช้ shared secret token ต่อ role (ไม่ใช่ per-user authentication)
   ถ้า token หลุด จะปลอมเป็นคนในกลุ่ม role นั้นได้ทุกคน ต้องย้ายไป Firebase Auth ID token
   verification แบบ per-user ตาม `SECURITY_MODEL.md` ข้อ 3.1 (ยังไม่ทำ)
3. 🟡 บั๊ก UI: ตัวเลข "Records" ที่หัวแอปผูกกับผลลัพธ์หลัง filter แทนที่จะโชว์จำนวนทั้งหมดจริง
   (ยังไม่แก้ ความเสี่ยงต่ำ ไม่เร่งด่วน)

ดูรายละเอียดเต็มที่ `docs/adr/ADR-0009-five-studio-application-model.md` (ส่วน "สถานะบั๊กความ
ปลอดภัยใน App 2")

---

## 3. App 3 — Dynamic Command Center (Platform Shell)

> **หมายเหตุ (ADR-0009):** Component นี้**ไม่ใช่ Studio ที่ 6** — จัดวางเป็น **"Platform Shell"**
> ใน Experience Layer แทน (ครอบมองภาพรวมของ 5 Studio: Ingest, Insight, Simulation, Operations,
> Governance & Security) เพราะหน้าที่จริงคือ Dashboard/Orchestration ไม่มี business capability
> ของตัวเอง — ดูเหตุผลเต็มที่ `docs/adr/ADR-0009-five-studio-application-model.md`

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

## 3.5 Component ที่วางแผนไว้ (ยังไม่มีโค้ด) — ตาม ADR-0009

> Component ทั้ง 3 นี้เป็น**เป้าหมายสถาปัตยกรรมเท่านั้น** ยังไม่มี repo ยังไม่มีการเริ่มเขียนโค้ด
> ห้ามอ้างอิงเป็นของที่ใช้งานได้จริงในเอกสารอื่นจนกว่าจะมีการอัปเดตสถานะตรงนี้ก่อน

| Component | Studio ที่แมป | หน้าที่ตามแผน | สถานะ |
|---|---|---|---|
| `dynamic-plan-ai` | Simulation Studio | ออกแบบสถาปัตยกรรม/จำลองสถานการณ์/Roadmap | ❌ ยังไม่มี repo |
| `dynamic-ops-ai` | Deployment / Operations Studio | Deploy, Monitoring | ❌ ยังไม่มี repo |
| `dynamic-guard-ai` | Governance & Security Studio | Security Guardrails, PDPA, Audit Log (ของที่จะย้ายมาจาก App 2 — ดูหมายเหตุในข้อ 2) | ❌ ยังไม่มี repo |

---

## 4. Data Layer

> **หมายเหตุ (ตรวจสอบ 2026-08-03):** ตารางด้านล่างนี้คือ **target design** ตามสถาปัตยกรรม
> ที่วางแผนไว้ **ไม่ใช่สถานะจริงของ `dynamic-insight-ai` ในปัจจุบัน** — ตรวจสอบโค้ดจริงแล้วพบว่า
> โปรเจกต์นี้ไม่มีการเชื่อมต่อ Firestore เลย (ไม่มี Firebase project) ข้อมูลทั้งหมดเก็บเป็น
> local JSON บนเครื่อง (`data/*.json`) การต่อ Firestore จริงตาม design นี้ยังไม่ได้เริ่ม

| หัวข้อ | รายละเอียด |
|---|---|
| **หน้าที่** | เก็บข้อมูลจริงของแต่ละ tenant |
| **Collections หลัก (ตามแผน)** | `extracted_data`, `analysis_audit_log`, (จะเพิ่ม `governance_metrics` เมื่อ persist จริง) |
| **การเข้าถึง (ตามแผน)** | ผ่าน backend (Firebase Admin SDK) เท่านั้น ห้าม client เข้าถึงตรง |
| **Isolation** | แยกต่อ tenant (รูปแบบยังไม่ตัดสินใจสุดท้าย — ดู `ENTERPRISE_ARCHITECTURE.md` หัวข้อ "Tenant Isolation Model") |

---

## 5. Identity Layer — Firebase Auth

| หัวข้อ | รายละเอียด |
|---|---|
| **หน้าที่** | ยืนยันตัวตนผู้ใช้และออก ID token ที่ backend ใช้ verify สิทธิ์ |
| **สถานะปัจจุบัน** | ยังไม่ได้ใช้ Firebase Auth จริงใน App 2 — `getUserRole()` เวอร์ชัน fixed แก้ไม่ให้เชื่อ header ที่ client ปลอมได้แล้ว (ดึงจาก token ที่ verify แล้วเท่านั้น) แต่ token ที่ใช้ยังเป็น shared secret ต่อ role ไม่ใช่ per-user token จาก Firebase Auth ยังไม่มี Firebase project สำหรับ Auth อยู่จริง |
| **เป้าหมาย** | ทุก endpoint ที่แก้ไข/อ่านข้อมูลสำคัญต้อง verify ID token ก่อนเสมอ แบบ per-user ตาม `SECURITY_MODEL.md` ข้อ 3.1 |

---

## 6. ตาราง Component Ownership สรุป

| Component | เจ้าของ (ทีม) | Repo |
|---|---|---|
| App 1 — Dynamic Ingest AI | ทีม implement | `dynamic-ingest-ai` |
| App 2 — Dynamic Insight AI | ทีม implement (ยังถือ scope security ไว้ชั่วคราว — ดูข้อ 2) | `dynamic-insight-ai` |
| App 3 — Dynamic Command Center (Platform Shell) | ทีมขาย + ทีม implement | ยังไม่สร้าง repo |
| `dynamic-plan-ai` (ยังไม่มีโค้ด) | ยังไม่กำหนด | ยังไม่สร้าง repo |
| `dynamic-ops-ai` (ยังไม่มีโค้ด) | ยังไม่กำหนด | ยังไม่สร้าง repo |
| `dynamic-guard-ai` (ยังไม่มีโค้ด) | ยังไม่กำหนด (จะรับช่วง security scope จาก App 2) | ยังไม่สร้าง repo |
| Platform Foundation (เอกสารนี้) | ทุกทีมร่วมกัน | `CloudForge-Platform-Foundation` |

การเปลี่ยนแปลงที่กระทบมากกว่า 1 component ต้องบันทึกเป็น ADR ใน `docs/adr/` ก่อนแก้จริง
ตามหลักการใน `PLATFORM_PRINCIPLES.md` ข้อ 7

ดูเหตุผลของการปรับ Component Model นี้ทั้งหมดได้ที่
`docs/adr/ADR-0009-five-studio-application-model.md`
