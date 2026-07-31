# Canonical Data Model — CloudForge Platform Foundation

> เอกสารนี้นิยาม Schema กลางของข้อมูลทุก Entity ในระบบ ใช้เป็นโครงสร้างอ้างอิงหลักระหว่าง App 1, App 2 และ App 3

---

## 1. ExtractedRecord
ข้อมูลที่สกัดได้จากเอกสารดิบโดย App 1 (Dynamic Ingest AI) ส่งต่อให้ App 2 วิเคราะห์

| Field | Type | Description |
|---|---|---|
| `recordId` | string | รหัสอ้างอิงเรคอร์ด |
| `tenantId` | string | รหัสองค์กร/ผู้ใช้งาน |
| `phase` | string | `current_student` \| `teacher_dorm` \| `finance` \| `historical` |
| `sourceFileRef` | string | Path หรือ URL ของไฟล์ต้นทาง |
| `extractedFields` | object | ข้อมูล Key-Value ที่สกัดได้จากเอกสาร |
| `confidenceScore` | number | ค่าความเชื่อมั่นในการสกัดข้อมูล (0.0 - 1.0) |
| `containsPII` | boolean | มีข้อมูลส่วนบุคคลหรือไม่ |
| `tokenizedFields` | array[string] | รายการชื่อ Field ที่ถูกทำ Tokenization เพื่อซ่อน PII |
| `createdAt` | string (ISO8601) | วันเวลาที่สร้างข้อมูล |

---

## 2. AuditLogEntry
บันทึกการตรวจสอบความปลอดภัย การเข้าถึง และ Governance โดย App 2 (Dynamic Insight AI)

| Field | Type | Description |
|---|---|---|
| `logId` | string | รหัสบันทึก Audit |
| `tenantId` | string | รหัสองค์กร |
| `batchId` | string | รหัสชุดข้อมูลที่ทำการสแกน/วิเคราะห์ |
| `category` | string | `prompt_injection_test` \| `cost_guard` \| `pdpa_cascade` \| `secret_scan` \| `access` |
| `action` | string | รายละเอียดการกระทำหรือเหตุการณ์ |
| `result` | string | `pass` \| `fail` \| `warning` |
| `createdAt` | string (ISO8601) | วันเวลาที่บันทึก |

---

## 3. GovernanceMetric
ข้อมูลเมทริกซ์สรุปการใช้งานและค่าใช้จ่ายของแต่ละ Tenant

| Field | Type | Description |
|---|---|---|
| `tenantId` | string | รหัสองค์กร |
| `totalRequests` | number | จำนวน Request สะสมที่ใช้งาน API/Agent |
| `totalCost` | number | ค่าใช้จ่ายสะสม (บาท/USD) |
| `lastUpdated` | string (ISO8601) | วันเวลาอัปเดตล่าสุด |

---

## 4. TenantConfig
โครงสร้างข้อมูลสำหรับการตั้งค่า Tenant ใหม่ผ่าน Setup Wizard (App 3)

| Field | Type | Description |
|---|---|---|
| `tenantId` | string | รหัสองค์กรที่ถูกสร้างขึ้น |
| `tenantName` | string | ชื่อองค์กร/โปรเจกต์ |
| `phaseMapping` | object | การจับคู่หมวดหมู่เอกสารเข้ากับ Phase |
| `mode` | string | `demo` \| `live` |
| `serviceAccountRef` | string | อ้างอิง Service Account ของ Tenant |
| `createdAt` | string (ISO8601) | วันเวลาที่สร้าง Tenant |