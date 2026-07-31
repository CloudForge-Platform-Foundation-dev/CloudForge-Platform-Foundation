# Security Model: Zero Trust Architecture

> Sprint 4 — CloudForge Platform Foundation (อัปเดตหลัง Sprint 5: สะท้อนการแก้ security bug จริงในแอป 2)
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

| หลักการ | ความหมายเชิงปฏิบัติ | ตัวอย่างที่ละเมิดหลักการ (พบจริงในแอป 2 — แก้แล้วตาม commit `c0d4677`) |
|---|---|---|
| Never trust, always verify | ทุก request ต้องผ่านการ verify identity token จริง ไม่เชื่อ header ที่ client ส่งมาเอง | เดิม `getUserRole()`/`getUserEmail()` เชื่อ header ที่ client กำหนดเองได้ทั้งหมด — แก้แล้ว: ผูกกับ secret token ที่ verify จาก environment variable |
| Fail-closed by default | เมื่อไม่แน่ใจสิทธิ์ ต้องปฏิเสธก่อน ไม่ใช่อนุญาตก่อน | เดิม Firestore rule `allow read: if true` — แก้แล้ว: เปลี่ยนเป็น `allow read: if false` ทั้ง 2 collection |
| Least privilege | ให้สิทธิ์เท่าที่จำเป็นต่องานนั้นเท่านั้น | Default role เดิมเป็น `admin` (แก้ไปเป็น `viewer` แล้วในรอบก่อน) |
| Explicit segmentation | แยก boundary ระหว่างแอปให้ชัด อย่าให้แอปหนึ่งเข้าถึงข้อมูลอีกแอปโดยตรงนอก contract ที่กำหนด | App 3 ในโหมด Live ต้องอ่าน Firestore แบบ read-only ผ่าน contract เท่านั้น ห้าม query ตรง |
| Assume breach | ออกแบบ audit log และ monitoring ให้พร้อมสืบสวนย้อนหลัง ไม่ใช่แค่ป้องกัน | เดิม audit log endpoint เช็คแค่ "มี key ครบ" ไม่ verify `userEmail` — แก้แล้ว: บังคับ `request.auth.token.email == resource.data.userEmail` ใน rule |

## 3. Identity & Access Management

### 3.1 Authentication
- ทุก request จากฝั่ง client ต้องแนบ **Firebase Auth ID token** ใน `Authorization` header
- Backend (ทุกแอป) ต้อง verify token ด้วย Firebase Admin SDK (`verifyIdToken`) ก่อนประมวลผลทุกครั้ง
  — **ห้าม trust ค่าที่ client ส่งมาเอง** (เช่น role, email, tenant ID) โดยไม่ผ่านการ verify
- Token ที่หมดอายุหรือ verify ไม่ผ่าน → ปฏิเสธด้วย `401` ทันที ไม่มี fallback เป็น guest/anonymous
- **สถานะจริงในแอป 2 (อัปเดต Sprint 5)**: ยังไม่ใช่ Firebase Auth ID token แบบ per-user เต็มรูปแบบ
  — ปัจจุบันเป็น shared secret token ต่อ role ที่อ่านจาก environment variable (ไม่ hardcode
  ในโค้ดแล้ว) พิสูจน์ตัวตนได้ระดับ "role ไหน" แต่ยังแยกไม่ได้ระดับ "ใครในบุคคลนั้น" —
  บันทึกเป็น TODO ในโค้ดและ Open Item ข้อ 11 ของเอกสารนี้

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
- Audit log write ต้องเช็ค `request.auth.token.email == resource.data.userEmail`
  ไม่ใช่แค่เช็คว่ามี field ครบ
- **สถานะจริงในแอป 2 (อัปเดต Sprint 5)**: 🟢 **แก้เสร็จและ push แล้ว** (commit `c0d4677`,
  repo `dynamic-insight-ai`) — `firestore.rules` เปลี่ยนเป็น fail-closed ทั้ง `extracted_data`
  และ `analysis_audit_log` ครบตามหลักการข้อนี้

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
- **สถานะจริงในแอป 2 (อัปเดต Sprint 5)**: 🟢 **แก้เสร็จและ push แล้ว** — เดิม
  `VALID_ROLE_TOKENS` เป็น string ลับ hardcode ไว้ในซอร์สโค้ด (และรั่วไปอยู่ใน client
  bundle ด้วยเพราะ frontend เป็นคนสร้าง header เอง) ย้ายไปอ่านจาก `ADMIN_AUTH_TOKEN`,
  `ANALYST_AUTH_TOKEN`, `VIEWER_AUTH_TOKEN` ใน environment variable แล้ว พร้อม fail-closed
  (demote เป็น `viewer`) ถ้าไม่ได้ตั้งค่า — ยังไม่ได้ทำเป็น CI step อัตโนมัติ

## 6. Audit & Logging

- ทุก action ที่แก้ไขหรืออ่านข้อมูล sensitive ต้องถูกบันทึกใน `AuditLogEntry`
  (ตาม `CANONICAL_DATA_MODEL.md`) พร้อม: ผู้กระทำ (จาก verified token ไม่ใช่ client-supplied),
  เวลา, action, tenant, ผลลัพธ์
- Audit log ต้องเป็น **append-only** — ไม่มี endpoint ใดแก้ไขหรือลบ audit log ย้อนหลังได้
- แนะนำ retention ของ audit log แยกจาก retention ของข้อมูลปฏิบัติการทั่วไป (ผูกกับ
  `TenantConfig` แต่ควรตั้งค่าขั้นต่ำระดับ compliance ไม่ให้ tenant ปรับต่ำกว่าที่กฎหมายกำหนด)
- **สถานะจริงในแอป 2 (อัปเดต Sprint 5)**: 🟢 **แก้เสร็จและ push แล้ว** — เดิม
  `getUserEmail()` เชื่อ header `x-user-email` จาก client แบบไม่ verify (ปลอมอีเมลคนอื่นใน
  audit log ได้) แก้แล้ว: อีเมลผูกกับ token ที่ verify แล้วเท่านั้น ไม่เชื่อ header อีกต่อไป

## 7. Threat Model (ระดับแพลตฟอร์ม)

| ภัยคุกคาม | ความเสี่ยงถ้าไม่ป้องกัน | มาตรการ | สถานะในแอป 2 |
|---|---|---|---|
| Public read บน Firestore rule ที่หลวม | ข้อมูลนักเรียน/ครูรั่วสู่สาธารณะ ใครรู้ project ID ก็อ่านได้ | Fail-closed rules ตามข้อ 4.1 | 🟢 แก้แล้ว |
| Client-controlled role/header | Privilege escalation โดยแก้ request header เอง | Verify ทุกอย่างจาก server-side token เท่านั้น | 🟢 แก้แล้ว (ระดับ role — ยังไม่ใช่ per-user) |
| Audit log impersonation | ปลอมอีเมลผู้อื่นในบันทึก audit log | ผูก userEmail กับ verified token เท่านั้น | 🟢 แก้แล้ว |
| Hardcoded secret ในซอร์สโค้ด | Token รั่วผ่าน repo หรือ client bundle | ย้ายไป environment variable | 🟢 แก้แล้ว |
| Cross-tenant data leakage | ลูกค้ารายหนึ่งเห็นข้อมูลอีกราย กระทบความน่าเชื่อถือทั้งแพลตฟอร์ม | Isolation test + query scoping ตาม tenant ID เสมอ | 🔴 ยังไม่มี |
| Prompt injection ผ่านข้อมูลที่ AI ประมวลผล | AI ถูกหลอกให้ทำ action หรือเปิดเผยข้อมูลนอกขอบเขต | ต้องมี Prompt Injection test | 🟡 มีการป้องกันในพรอมต์แล้ว แต่ยังไม่มี automated test ยืนยัน |
| Cost abuse / runaway API usage | ใช้งบ Gemini API เกินควบคุม (งบรวม ~30,000-70,000 บาท) | Cost guardrail + Cost Guard test | 🟡 มี endpoint ทดสอบแล้ว แต่ endpoint ยังไม่มี role protection (พบใหม่ Sprint 5 — ดู Open Items) |
| Secrets รั่วผ่าน repo | Credential หลุดเข้า git history | Secret scan ในทุก CI pipeline, ไม่ใช่แค่ manual endpoint | 🟡 มี endpoint แล้ว ยังไม่ใช่ CI step |

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
  — ผูกกับ test "PDPA delete จริง" ที่ระบุไว้ใน backlog แอป 2 (พบว่ามีการทำ PDPA cascade
  delete ทำงานจริงแล้วในโค้ด Sprint 5 — ยังไม่ได้ยืนยันด้วย automated test แยก)
- Retention period ต้อง config ได้ต่อ tenant ไม่ hardcode ในโค้ด (ตรงกับ backlog แอป 1)

## 10. สถานะการปฏิบัติตามจริง ณ Sprint 5 (Gap Analysis — อัปเดตหลังแก้ security bug จริง)

| หลักการในเอกสารนี้ | สถานะจริงในแอป 2 |
|---|---|
| Fail-closed Firestore rules | 🟢 แก้แล้ว — `allow read: if false` ทั้ง 2 collection (commit `c0d4677`) |
| Server-side token verification | 🟡 ปรับปรุงแล้วบางส่วน — verify token จาก env var + fail-closed demote ทำงานจริง แต่ยังเป็น shared token ต่อ role ไม่ใช่ Firebase Auth ID token แบบ per-user |
| Firestore จริงแทน in-memory | 🟡 ปรับปรุงแล้วบางส่วน — เปลี่ยนจาก in-memory เป็น disk-backed JSON แล้ว (ข้อมูลไม่หายตอน restart) แต่ยังไม่ใช่ Firestore ตาม `CANONICAL_DATA_MODEL.md` |
| Least privilege default role | 🟢 แก้แล้ว (`admin` → `viewer`) |
| Secret scanning | 🟡 endpoint สแกนจริงมีอยู่แล้ว และตอนนี้ไม่มี secret hardcode ให้สแกนเจอแล้ว แต่ยังไม่ใช่ CI step ระดับแพลตฟอร์ม |
| Audit log integrity check | 🟢 แก้แล้ว — เช็ค `userEmail` ตรงกับ auth token ทั้งระดับ Firestore rule และระดับ backend |
| Multi-tenant isolation test | 🔴 ยังไม่มี |
| Prompt injection test | 🟡 มีการป้องกันในพรอมต์ (PII sanitization, defense phrasing) แต่ยังไม่มี automated test ยืนยันแยก |
| Cost guardrail test | 🟡 มี endpoint ทดสอบ (`test-cost-guard`) แล้ว แต่พบว่ายังไม่มี role-based protection ครอบ endpoint นี้ (พบใหม่ระหว่างตรวจโค้ดจริง Sprint 5) |
| Governance test endpoints มี authorization guard | 🔴 พบใหม่ (Sprint 5): `test-firestore-rules`, `test-cost-guard`, `secret-scan` เรียกได้โดยไม่ต้องผ่าน role check เลย — ควรจำกัดให้ `admin`/`analyst` เท่านั้น |

> **สรุป**: ช่องโหว่ระดับ "public read" และ "hardcoded secret" ที่เป็นความเสี่ยงร้ายแรงที่สุด
> ถูกแก้และ push ขึ้น GitHub เรียบร้อยแล้ว (repo `dynamic-insight-ai`, commit `c0d4677`)
> สิ่งที่เหลือส่วนใหญ่เป็นงานเชิงสถาปัตยกรรมระยะยาว (Firestore จริง, per-user auth) และ
> automated test ที่ควรเพิ่มเพื่อป้องกัน regression ไม่ใช่ช่องโหว่ที่เปิดอยู่ตอนนี้ ยกเว้น
> endpoint ที่ไม่มี authorization guard ซึ่งเพิ่งพบใหม่และควรพิจารณาแก้ในรอบถัดไป

## 11. Open Items (รอ ADR หรือรอบแก้ไขถัดไป)

- [ ] เพิ่ม `authorizeRole()` guard ให้ endpoint `test-firestore-rules`, `test-cost-guard`,
      `secret-scan` ในแอป 2 (พบว่าตอนนี้เรียกได้โดยไม่ต้องผ่านการตรวจสิทธิ์เลย)
- [ ] วางแผนย้ายจาก shared role-token ไปเป็น Firebase Auth ID token แบบ per-user จริง
      (ต้องตั้งค่า Firebase Authentication ของผู้ใช้แต่ละคนก่อน — งานสถาปัตยกรรมแยกต่างหาก)
- [ ] วางแผนย้าย storage จาก disk-backed JSON ไปเป็น Firestore จริงตาม `CANONICAL_DATA_MODEL.md`
- [ ] ทำ multi-tenant isolation test แบบ automated
- [ ] ทำ prompt injection test แบบ automated (ปัจจุบันมีการป้องกันในพรอมต์แต่ยังไม่มี test ยืนยัน)
- [ ] ยกระดับ secret scanning และ Firestore rule test ให้เป็นส่วนหนึ่งของ CI pipeline
- [ ] รูปแบบ service-to-service auth ระหว่างแอป (signed JWT เอง หรือใช้ Firebase Auth custom token)
- [ ] Retention ขั้นต่ำของ audit log ที่ระดับแพลตฟอร์มบังคับ (ไม่ให้ tenant ตั้งต่ำกว่านี้)