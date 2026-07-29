# API Contract — CloudForge Platform Foundation

> เอกสารนี้กำหนดมาตรฐานการเชื่อมต่อ (API contract) ระหว่างแอปในเครือ อ้างอิง entity จาก
> `CANONICAL_DATA_MODEL.md` เป็นหลัก ทุก endpoint ที่กระทบมากกว่า 1 แอปต้องผ่านมาตรฐานนี้
> ห้ามแอปใดอ่าน Firestore ของอีกแอปตรงๆ ข้าม service (ตาม `ENTERPRISE_ARCHITECTURE.md` ข้อ 5)

---

## 1. หลักการทั่วไป

- ทุก request ต้องแนบ **Firebase Auth ID token** ใน header `Authorization: Bearer <token>`
  ห้ามใช้ custom header (เช่น `x-user-role`) เป็นแหล่งความจริงของสิทธิ์ผู้ใช้
- ทุก response คืนค่าเป็น JSON เท่านั้น
- ทุก endpoint ต้อง **fail-closed**: ถ้า verify token ไม่ผ่าน หรือ role ไม่มีสิทธิ์ ให้ตอบ
  `403 Forbidden` ไม่ใช่ปล่อยผ่านแบบ default
- ทุก request ที่อ่าน/เขียนข้อมูลต้องมี `tenantId` ที่ตรวจสอบแล้วว่าอยู่ในสิทธิ์ของ token นั้น
  ไม่รับ `tenantId` จาก query parameter ที่ client ส่งมาโดยไม่ตรวจ

---

## 2. Endpoint กลุ่ม App 1 → App 2 (ส่งข้อมูลที่สกัดแล้ว)

### `POST /api/v1/ingest/records`
ส่ง `ExtractedRecord` ที่สกัดเสร็จแล้วเข้าสู่ระบบวิเคราะห์

**Request body** (อ้างอิง schema จาก `CANONICAL_DATA_MODEL.md` ข้อ 2):
```json
{
  "tenantId": "string",
  "phase": "current_student | teacher_dorm | finance | historical",
  "sourceFileRef": "string",
  "extractedFields": { "...": "..." },
  "confidenceScore": 0.0,
  "containsPII": true,
  "tokenizedFields": ["string"]
}
```

**Response 201**:
```json
{ "recordId": "string", "createdAt": "ISO8601" }
```

**Response 403**: token ไม่ผ่าน หรือ tenantId ไม่ตรงกับสิทธิ์ของผู้เรียก

---

## 3. Endpoint กลุ่ม App 2 (Audit & Governance) — ให้ App 3 อ่านสถานะ

### `GET /api/v1/insight/audit-logs?tenantId=...&batchId=...&category=...`
คืนรายการ `AuditLogEntry` ตาม filter (phase/category/batch/confidence) — **read-only**

**Response 200**:
```json
{
  "logs": [
    {
      "logId": "string",
      "batchId": "string",
      "category": "prompt_injection_test | cost_guard | pdpa_cascade | secret_scan | access",
      "action": "string",
      "result": "pass | fail | warning",
      "createdAt": "ISO8601"
    }
  ],
  "totalRepositoryCount": 0
}
```

> ⚠️ **สำคัญ**: response ต้องคืนทั้ง `logs` (ผลหลังกรอง) และ `totalRepositoryCount`
> (จำนวนทั้งหมดจริงก่อนกรอง) แยกกันเสมอ — นี่คือจุดที่แก้บั๊ก UI "Records" ที่เคยผูกกับ
> ผลลัพธ์หลังกรองผิดพลาดใน Sprint ก่อน ห้ามให้เกิดซ้ำที่ระดับ API

### `GET /api/v1/insight/governance-metrics?tenantId=...`
คืนรายการ `GovernanceMetric` — **read-only**, ใช้ค่าจริงจาก `governance_metrics`
collection เท่านั้น ห้าม mock

---

## 4. Endpoint กลุ่ม App 3 (Orchestration) — Setup Wizard

### `POST /api/v1/orchestration/tenants`
สร้าง `TenantConfig` ใหม่ (ใช้เฉพาะทีม implement ผ่าน Setup Wizard)

**Request body**:
```json
{
  "tenantName": "string",
  "phaseMapping": { "...": "..." },
  "mode": "demo | live"
}
```

**Response 201**:
```json
{
  "tenantId": "string",
  "serviceAccountRef": "string",
  "createdAt": "ISO8601"
}
```

**สิทธิ์**: เฉพาะ role `admin` ของทีม implement เท่านั้นที่เรียก endpoint นี้ได้

---

## 5. โหมด Demo ของ App 3

เมื่อ `mode: "demo"` App 3 **ต้องไม่เรียก endpoint จริงข้างต้นเลย** ใช้ mock data ฝั่ง
client/edge function แทนทั้งหมด เพื่อไม่ให้มีทางแตะ Firestore จริงของลูกค้ารายใดโดยไม่ตั้งใจ
(ตาม `PLATFORM_PRINCIPLES.md` ข้อ 3)

---

## 6. Error Response มาตรฐาน

ทุก endpoint ที่ error ต้องตอบรูปแบบเดียวกัน:

```json
{
  "error": {
    "code": "string (เช่น UNAUTHORIZED, TENANT_MISMATCH, VALIDATION_ERROR)",
    "message": "string อธิบายสั้นๆ"
  }
}
```

| HTTP Status | ใช้เมื่อ |
|---|---|
| `400` | request body ไม่ตรง schema |
| `403` | token ไม่ผ่าน หรือ role ไม่มีสิทธิ์ หรือ tenantId ไม่ตรง |
| `404` | ไม่พบ resource |
| `500` | error ฝั่ง server (ต้อง log แต่ไม่คืน stack trace ให้ client) |

---

## 7. สิ่งที่ยังไม่ตัดสินใจ (รอ ADR)

- [ ] App 3 เรียก API แบบ REST (ตามที่ร่างในเอกสารนี้) หรือ subscribe ผ่าน Firestore
      listener โดยตรง (ยังไม่ชั่งน้ำหนักข้อดี-ข้อเสียเรื่อง audit control)
- [ ] จะมี API versioning strategy อย่างไรเมื่อ schema เปลี่ยน (`/v1/` → `/v2/`)
- [ ] Rate limit ต่อ endpoint ควรตั้งเท่าไหร่ (ผูกกับ Cost Guard/Token Guardrails ของ App 2)