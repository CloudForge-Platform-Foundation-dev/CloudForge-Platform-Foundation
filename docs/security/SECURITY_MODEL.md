# Security Model: Zero Trust Architecture

> Sprint 4 — CloudForge Platform Foundation
> สถานะ: Draft สำหรับ review
> เอกสารนี้อ้างอิงและขยายความจาก `docs/vision/PLATFORM_PRINCIPLES.md` (หลักการบังคับ 7 ข้อ)
> และดึงบทเรียนจริงจากบั๊กที่พบในแอป 2 (`dynamic-insight-ai`) มาเป็นกรณีศึกษา

---

## 1. เป้าหมายและขอบเขต

เอกสารนี้กำหนดสถาปัตยกรรมความปลอดภัยระดับแพลตฟอร์มที่แอป 1, 2, 3 ทุกแอปต้องยึดถือ
โดยใช้หลัก **Zero Trust**: ไม่มี component ไหน "เชื่อ" component อื่นโดยอัตโนมัติ
ไม่ว่าจะอยู่ใน network เดียวกันหรือไม่ก็ตาม ทุก request ต้องพิสูจน์ตัวตนและสิทธิ์ใหม่เสมอ

ขอบเขตครอบคลุม: identity & access, data protection, network/API boundary,
secrets management, audit & logging, multi-tenant isolation, และ threat model
ไม่ครอบคลุม: physical security ของ infrastructure provider (Google Cloud/Firebase
รับผิดชอบส่วนนั้นตาม shared responsibility model)

## 2. หลักการ Zero Trust (มาจาก PLATFORM_PRINCIPLES.md ข้อ fail-closed by default)

| หลักการ | ความหมายเชิงปฏิบัติ | ตัวอย่างที่ละเมิดหลักการ (พบจริงในแอป 2) |
|---|---|---|
| Never trust, always verify | ทุก request ต้องผ่านการ verify identity token จริง ไม่เชื่อ header ที่ client ส่งมาเอง | `getUserRole()` เชื่อ header `x-user-role` ที่ client กำหนดเองได้ทั้งหมด |
| Fail-closed by default | เมื่อไม่แน่ใจสิทธิ์ ต้องปฏิเสธก่อน ไม่ใช่อนุญาตก่อน | Firestore rule `allow read: if true` — เปิด public โดย default แทนที่จะปิดไว้ก่อน |
| Least privilege | ให้สิทธิ์เท่าที่จำเป็นต่องานนั้นเท่านั้น | Default role เดิมเป็น `admin` (แก้ไปเป็น `viewer` แล้วในรอบก่อน) |
| Explicit segmentation | แยก boundary ระหว่างแอปให้ชัด อย่าให้แอปหนึ่งเข้าถึงข้อมูลอีกแอปโดยตรงนอก contract ที่กำหนด | App 3 ในโหมด Live ต้องอ่าน Firestore แบบ read-only ผ่าน contract เท่านั้น ห้าม query ตรง |
| Assume breach | ออกแบบ audit log และ monitoring ให้พร้อมสืบสวนย้อนหลัง ไม่ใช่แค่ป้องกัน | Audit log endpoint เช็คแค่ "มี key ครบ" ไม่ verify ว่า `userEmail` ตรงกับผู้ login จริง |

## 3. Identity & Access Management

### 3.1 Authentication
- ทุก request จากฝั่ง client ต้องแนบ **Firebase Auth ID token** ใน `Authorization` header
- Backend (ทุกแอป) ต้อง verify token ด้วย Firebase Admin SDK (`verifyIdToken`) ก่อนประมวลผลทุกครั้ง
  — **ห้าม trust ค่าที่ client ส่งมาเอง** (เช่น role, email, tenant ID) โดยไม่ผ่านการ verify
- Token ที่หมดอายุหรือ verify ไม่ผ่าน → ปฏิเสธด้วย `401` ทันที ไม่มี fallback เป็น guest/anonymous

### 3.2 Authorization
- ใช้ **role-based access control (RBAC)** ขั้นต่ำ 3 ระดับต่อ tenant: `viewer`, `editor`, `admin`
- Role ต้องถูกเก็บฝั่ง server (Firestore custom claims หรือ collection แยก) ไม่ใช่ค่าที่ client ส่งมา
- Default role เมื่อไม่พบข้อมูล = `viewer` (fail-closed) — ห้าม default เป็น `admin` เด็ดขาด
- Cross-tenant access ต้องถูกปฏิเสธที่ระดับ query/rule ไม่ใช่แค่ระดับ UI

### 3.3 Service-to-service (App1 → App2 → App3)
- การเรียกระหว่างแอปต้องผ่าน service account หรือ signed token เฉพาะ ไม่ใช้ credential ของผู้ใช้ปลายทาง
- App 3 โหมด Live ต้องได้รับสิทธิ์ **read-only** เท่านั้นตาม `API_CONTRACT.md` — ไม่มีสิทธิ์ write กลับเข้า Firestore ของ App 1/2

## 4. Data Protection

### 4.1 Firestore Security Rules
- กฎเหล็ก: **`allow read/write: if false;` คือค่าเริ่มต้น** ของทุก collection ใหม่
  แล้วค่อยเปิดสิทธิ์เฉพาะ path ที่จำเป็น พร้อมเงื่อนไข auth ที่ตรวจสอบได้จริง
- ห้ามใช้ `allow read: if true` กับ collection ที่มีข้อมูลส่วนบุคคล (PII) โดยเด็ดขาด
  ไม่ว่าจะอยู่ในช่วง prototype หรือ production — นี่คือบทเรียนตรงจากบั๊กในแอป 2
  (`extracted_data`, `analysis_audit_log` เปิด public read มาก่อน)
- Audit log write ต้องเช็ค `request.auth.token.email == resource.data.userEmail`
  ไม่ใช่แค่เช็คว่ามี field ครบ

### 4.2 Encryption
- Data at rest: ใช้ encryption ที่ Firestore/Firebase จัดให้โดย default (ไม่ปิด)
- Data in transit: บังคับ HTTPS/TLS ทุก endpoint ไม่มี HTTP fallback
- PII ที่ต้อง reversible tokenization (ตามที่ระบุไว้ใน backlog ของแอป 1) ต้องระบุ
  key management policy แยกต่างหาก และต้องแจ้งไว้ในสัญญากับลูกค้าอย่างชัดเจน

### 4.3 Multi-tenant isolation
- ต้อง**พิสูจน์ได้**ว่า tenant A เข้าถึงข้อมูล tenant B ไม่ได้ ไม่ว่าจะผ่าน bug ใน query
  หรือผ่าน rule ที่หลวมเกินไป (อ้างอิงประเด็นค้างใน `PLATFORM_PRINCIPLES.md`)
- แนะนำให้มี automated test ที่จำลอง cross-tenant access แล้วยืนยันว่าถูกปฏิเสธ
  เป็นส่วนหนึ่งของ CI ก่อน merge ทุกครั้ง (ดูหัวข้อ 6)

## 5. Secrets Management

- ห้าม hardcode API key, service account credential ใน source code หรือ commit ขึ้น repo
- ใช้ environment variable หรือ secret manager ของ cloud provider เท่านั้น
- `secret-scan` endpoint ที่มีอยู่แล้วในแอป 2 (สแกนไฟล์จริงแบบ recursive) ควรถูกยกระดับเป็น
  pre-commit hook หรือ CI step ระดับแพลตฟอร์ม ไม่ใช่แค่ endpoint แยกในแอปเดียว

## 6. Audit & Logging

- ทุก action ที่แก้ไขหรืออ่านข้อมูล sensitive ต้องถูกบันทึกใน `AuditLogEntry`
  (ตาม `CANONICAL_DATA_MODEL.md`) พร้อม: ผู้กระทำ (จาก verified token ไม่ใช่ client-supplied),
  เวลา, action, tenant, ผลลัพธ์
- Audit log ต้องเป็น **append-only** — ไม่มี endpoint ใดแก้ไขหรือลบ audit log ย้อนหลังได้
- แนะนำ retention ของ audit log แยกจาก retention ของข้อมูลปฏิบัติการทั่วไป (ผูกกับ
  `TenantConfig` แต่ควรตั้งค่าขั้นต่ำระดับ compliance ไม่ให้ tenant ปรับต่ำกว่าที่กฎหมายกำหนด)

## 7. Threat Model (ระดับแพลตฟอร์ม)

| ภัยคุกคาม | ความเสี่ยงถ้าไม่ป้องกัน | มาตรการ |
|---|---|---|
| Public read บน Firestore rule ที่หลวม | ข้อมูลนักเรียน/ครูรั่วสู่สาธารณะ ใครรู้ project ID ก็อ่านได้ | Fail-closed rules ตามข้อ 4.1 (บั๊กจริงที่พบ, ยังไม่แก้) |
| Client-controlled role/header | Privilege escalation โดยแก้ request header เอง | Verify ทุกอย่างจาก server-side token เท่านั้น |
| Cross-tenant data leakage | ลูกค้ารายหนึ่งเห็นข้อมูลอีกราย กระทบความน่าเชื่อถือทั้งแพลตฟอร์ม | Isolation test + query scoping ตาม tenant ID เสมอ |
| Prompt injection ผ่านข้อมูลที่ AI ประมวลผล | AI ถูกหลอกให้ทำ action หรือเปิดเผยข้อมูลนอกขอบเขต | ต้องมี Prompt Injection test ตามที่ระบุใน backlog แอป 2 |
| Cost abuse / runaway API usage | ใช้งบ Gemini API เกินควบคุม (งบรวม ~30,000-70,000 บาท) | Cost guardrail ตาม `PLATFORM_PRINCIPLES.md` + Cost Guard test ที่ค้างอยู่ในแอป 2 |
| Secrets รั่วผ่าน repo | Credential หลุดเข้า git history | Secret scan ในทุก CI pipeline, ไม่ใช่แค่ manual endpoint |

## 8. Incident Response (ระดับ baseline)

1. ตรวจพบ/ได้รับแจ้งเหตุ → บันทึกลง audit log ทันที พร้อม severity
2. ถ้าเป็นข้อมูลรั่ว (เช่นกรณี public read) → ปิดช่องทางก่อน (เปลี่ยน rule เป็น `if false`)
   แล้วค่อยสืบสวนขอบเขตความเสียหายทีหลัง — ไม่รอสืบสวนให้เสร็จก่อนปิดช่องโหว่
3. แจ้งผู้เกี่ยวข้อง (ทีม implement / ลูกค้า ถ้ากระทบข้อมูลลูกค้าจริง) ตามระดับความรุนแรง
4. บันทึก postmortem แบบไม่กล่าวโทษบุคคล (blameless) เก็บไว้ใน `docs/security/incidents/`
   (โฟลเดอร์ยังไม่มี — ควรสร้างเมื่อเกิดเหตุจริงครั้งแรก)

## 9. Compliance Alignment (PDPA)

- ข้อมูลนักเรียน/ครูเข้าข่ายข้อมูลส่วนบุคคลตาม PDPA — ต้องมี legal basis ในการเก็บ/ประมวลผล
- ต้องรองรับสิทธิ์เจ้าของข้อมูล: ขอลบ (right to erasure), ขอดูข้อมูล, ขอแก้ไข
  — ผูกกับ test "PDPA delete จริง" ที่ระบุไว้ใน backlog แอป 2
- Retention period ต้อง config ได้ต่อ tenant ไม่ hardcode ในโค้ด (ตรงกับ backlog แอป 1)

## 10. สถานะการปฏิบัติตามจริง ณ Sprint 4 (Gap Analysis)

| หลักการในเอกสารนี้ | สถานะจริงในแอป 2 ตอนนี้ |
|---|---|
| Fail-closed Firestore rules | 🔴 ยังเป็น `allow read: if true` อยู่ ยังไม่แก้ |
| Server-side token verification | 🔴 ยังเชื่อ header `x-user-role` จาก client |
| Firestore จริงแทน in-memory | 🔴 ยังเป็น in-memory array |
| Least privilege default role | 🟢 แก้แล้ว (`admin` → `viewer`) |
| Secret scanning | 🟢 มี endpoint แล้ว แต่ยังไม่ใช่ CI step ระดับแพลตฟอร์ม |
| Audit log integrity check | 🔴 ยังไม่เช็ค `userEmail` ตรงกับ auth token |
| Multi-tenant isolation test | 🔴 ยังไม่มี |
| Prompt injection test | 🔴 ยังไม่มี |
| Cost guardrail test | 🔴 ยังไม่มี |

> **สรุป**: เอกสารนี้คือ "เป้าหมาย" ระดับแพลตฟอร์ม แต่ช่องว่างที่ใหญ่ที่สุดคือแอป 2
> ซึ่งยังไม่ตรงกับหลักการข้อ 3.1, 3.2, 4.1, 6 เลย — ยืนยันคำแนะนำเดิมว่าควรแก้ security bug
> ในแอป 2 ก่อนเริ่มงานอื่น

## 11. Open Items (รอ ADR)

- [ ] รูปแบบ service-to-service auth ระหว่างแอป (signed JWT เอง หรือใช้ Firebase Auth custom token)
- [ ] Retention ขั้นต่ำของ audit log ที่ระดับแพลตฟอร์มบังคับ (ไม่ให้ tenant ตั้งต่ำกว่านี้)
- [ ] เครื่องมือ secret scanning ระดับ CI (เช่น gitleaks/trufflehog) ที่จะใช้ร่วมกันทุกแอป