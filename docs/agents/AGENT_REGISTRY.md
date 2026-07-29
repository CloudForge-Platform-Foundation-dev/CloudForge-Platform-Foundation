# Agent Registry: มาตรฐาน AI Agent

> Sprint 5 — CloudForge Platform Foundation
> สถานะ: Draft สำหรับ review
> เอกสารนี้เชื่อมกับ `docs/security/SECURITY_MODEL.md` (threat model ข้อ prompt injection,
> cost abuse) และ `docs/governance/GOVERNANCE_MODEL.md` (cost governance)

---

## 1. เป้าหมายและขอบเขต

ทุกแอปในแพลตฟอร์ม (App 1, 2, 3) มีจุดที่เรียกใช้ AI model (Gemini API) เป็นส่วนหนึ่งของ
การทำงาน — เอกสารนี้กำหนดว่า **AI agent แต่ละตัวคืออะไร ใช้ที่ไหน มีขอบเขตอำนาจแค่ไหน
และต้องผ่านมาตรฐานอะไรก่อนขึ้น production**

"Agent" ในที่นี้หมายถึงหน่วยของ prompt + model + tool/permission ที่ถูกเรียกใช้เพื่อทำงาน
เฉพาะอย่าง (เช่น extraction, insight analysis) ไม่ใช่แค่ raw API call ทั่วไป

ขอบเขตครอบคลุม: registry กลาง, naming standard, required metadata, lifecycle,
testing requirement, cost/security guardrail ที่ผูกกับแต่ละ agent
ไม่ครอบคลุม: รายละเอียด prompt engineering เชิงลึกของแต่ละ agent (อยู่ในเอกสารเฉพาะแอป)

## 2. หลักการ

| หลักการ | ความหมาย |
|---|---|
| Registry เดียว ความจริงเดียว | Agent ทุกตัวในทุกแอปต้องลงทะเบียนใน registry นี้ ห้ามมี agent ที่ไม่มีใครรู้ว่ามีอยู่ |
| Least privilege ต่อ agent | แต่ละ agent เข้าถึงเฉพาะข้อมูล/tool ที่จำเป็นต่องานนั้น ไม่ใช่สิทธิ์เต็มระบบ |
| ทุก agent ต้องมี owner | มีคนรับผิดชอบด้าน prompt, cost, และผลลัพธ์ของ agent นั้นชัดเจน |
| Testable ก่อนขึ้น production | agent ต้องผ่าน test ชุดขั้นต่ำ (ข้อ 6) ก่อนเปิดใช้กับข้อมูลลูกค้าจริง |
| Cost-bounded | ทุก agent ต้องมี budget guardrail ผูกกับตัวเอง เชื่อมกับ cost governance ระดับแพลตฟอร์ม |

## 3. Agent Registry (รายการปัจจุบัน)

| Agent ID | แอปที่ใช้ | หน้าที่ | Model | สถานะ |
|---|---|---|---|---|
| `app1-extraction-agent` | App 1 (Dynamic Ingest AI) | สกัดข้อมูลจากไฟล์ดิบ (นักเรียน/ครู/การเงิน) เป็น structured record | Gemini | 🟢 ตรวจสอบแล้ว (มี 5 จุดต้องระวังก่อนขายจริง — ดู README) |
| `app2-insight-agent` | App 2 (Dynamic Insight AI) | วิเคราะห์/สรุปข้อมูลที่สกัดแล้ว เขียนผลลง `analysis_audit_log` | Gemini | 🔴 ยังไม่ผ่านมาตรฐานความปลอดภัย (ดูข้อ 6) |
| `app3-orchestration-agent` | App 3 (แนวคิด ยังไม่สร้าง) | ยังไม่นิยามชัดเจน — คาดว่าเป็นตัวประสาน query ระหว่าง Demo/Live/Setup Wizard | ยังไม่ตัดสินใจ | ⚪ ยังไม่เริ่มสร้าง |

> หมายเหตุ: ตารางนี้คือ**จุดเดียว**ที่ต้องอัปเดตทุกครั้งที่มีการเพิ่ม/แก้ agent ใหม่
> ห้ามสร้าง agent ใหม่ในโค้ดโดยไม่มาลงทะเบียนที่นี่ก่อน

## 4. Naming Standard

รูปแบบชื่อ: `{app-id}-{หน้าที่}-agent` ตัวพิมพ์เล็กทั้งหมด คั่นด้วย `-`

ตัวอย่างที่ถูกต้อง: `app1-extraction-agent`, `app2-insight-agent`
ตัวอย่างที่ผิด: `Agent1`, `helper_bot`, `gemini-caller` (ไม่บอกหน้าที่/เจ้าของ)

## 5. Required Metadata ต่อ Agent

ทุก agent ที่ลงทะเบียนต้องมี metadata ต่อไปนี้ครบ (แนะนำเก็บเป็นไฟล์ `docs/agents/{agent-id}.md`
แยกต่างหากเมื่อมีรายละเอียดมากขึ้น):

| Field | คำอธิบาย |
|---|---|
| `agent_id` | ชื่อตาม naming standard ข้อ 4 |
| `owner` | ผู้รับผิดชอบ prompt/ผลลัพธ์ของ agent นี้ |
| `purpose` | หน้าที่โดยสรุป 1-2 ประโยค |
| `model` | model ที่ใช้ (เช่น Gemini รุ่นไหน) |
| `input_schema` | รูปแบบ input ที่ agent รับ (อ้างอิง `CANONICAL_DATA_MODEL.md` ถ้าเกี่ยวข้อง) |
| `output_schema` | รูปแบบ output ที่ agent คืนกลับ |
| `permissions` | สิทธิ์เข้าถึงข้อมูล/tool ที่ agent มี (ต้องเป็น least privilege) |
| `cost_budget` | งบต่อ request หรือต่อเดือนของ agent นี้ (ผูกกับ cost governance) |
| `prompt_version` | เวอร์ชันของ prompt ปัจจุบัน (ดูข้อ 7) |
| `status` | `draft` / `testing` / `production` / `deprecated` |

## 6. Testing Standard ก่อนขึ้น Production

Agent จะเปลี่ยนสถานะเป็น `production` ได้ต่อเมื่อผ่าน test ขั้นต่ำต่อไปนี้ครบ
(เชื่อมตรงกับ Threat Model ใน `SECURITY_MODEL.md` ข้อ 7):

| Test | วัตถุประสงค์ | สถานะปัจจุบัน (`app2-insight-agent`) |
|---|---|---|
| Prompt Injection test | ยืนยันว่า agent ไม่ถูกหลอกให้ทำ action หรือเปิดเผยข้อมูลนอกขอบเขตผ่าน input ที่ปนเปื้อน | 🔴 ยังไม่มี |
| Cost Guard test | ยืนยันว่า agent ไม่ใช้งบเกิน `cost_budget` ที่กำหนด | 🔴 ยังไม่มี |
| PII edge case test | ยืนยันว่า agent จัดการข้อมูลส่วนบุคคลถูกต้องแม้ในกรณีขอบ (เช่น ชื่อซ้ำ, format แปลก) | 🟡 มีบางส่วนในแอป 1 ต้องทำเพิ่ม |
| Output schema validation | ยืนยันว่า output ตรงตาม `output_schema` ที่ประกาศไว้เสมอ | 🔴 ยังไม่มี |
| Least privilege check | ยืนยันว่า agent เข้าถึงได้เฉพาะที่ระบุใน `permissions` จริง ไม่เกินกว่านั้น | 🔴 ยังไม่มี |

> **ข้อสรุปสำคัญ**: `app2-insight-agent` ยังไม่ผ่านเกณฑ์ข้อไหนเลยในตารางนี้ ตรงกับสถานะ
> security bug ที่ยังค้างอยู่ในแอป 2 — agent นี้ไม่ควรถูกจัดว่า `production-ready`
> จนกว่าจะแก้ปัญหาใน `SECURITY_MODEL.md` ข้อ 10 (Gap Analysis) ให้ครบก่อน

## 7. Prompt Versioning

- Prompt ของทุก agent ต้องมีเลขเวอร์ชัน (semantic-style: `v1`, `v2`, ...) และเก็บ history
  ของการเปลี่ยนแปลงไว้ (เช่นใน commit message หรือไฟล์ `CHANGELOG` เฉพาะ agent)
- การเปลี่ยน prompt ที่กระทบ output schema หรือ permission ต้องผ่าน review เหมือนการเปลี่ยน
  code อื่น ไม่ใช่แก้ตรงๆ โดยไม่มี record

## 8. Agent Lifecycle - **draft**: กำลังออกแบบ prompt/schema ยังไม่เชื่อมข้อมูลจริง
- **testing**: เชื่อมข้อมูล sandbox/mock แล้ว กำลังรัน test ชุดข้อ 6
- **production**: ผ่าน test ครบ ใช้งานกับข้อมูลลูกค้าจริงได้
- **deprecated**: เลิกใช้แล้ว แต่เก็บ record ไว้เพื่อ audit trail ย้อนหลัง

Agent ห้ามข้ามขั้นจาก `draft`/`testing` ไป `production` โดยไม่ผ่าน test ครบตามข้อ 6

## 9. เชื่อมโยงกับ Governance และ Security

- Cost budget ของแต่ละ agent ต้องรวมกันไม่เกินงบ Gemini API รวมของโปรเจกต์
  (~30,000-70,000 บาท ตาม `GOVERNANCE_MODEL.md` ข้อ 5)
- Agent ที่เข้าถึงข้อมูล PII ต้องผ่าน data governance lifecycle ตาม
  `GOVERNANCE_MODEL.md` ข้อ 4.2 ด้วย ไม่ใช่แค่ test ทาง technical
- ทุก agent ที่ status เป็น `production` ควรมี metric เข้า `GovernanceMetric`
  (เช่น request count, cost, error rate) ตามที่ระบุใน `GOVERNANCE_MODEL.md` ข้อ 7

## 10. Open Items

- [x] เขียนไฟล์ metadata แยกต่อ agent (`docs/agents/app1-extraction-agent.md` ฯลฯ)
      เมื่อรายละเอียดมากพอที่จะแยกออกจากตารางรวม
- [ ] นิยาม `app3-orchestration-agent` ให้ชัดเจนเมื่อเริ่มออกแบบ App 3 จริง
- [ ] ตัดสินใจเครื่องมือ/framework สำหรับรัน test ชุดข้อ 6 แบบอัตโนมัติ (ผูกกับ CI)