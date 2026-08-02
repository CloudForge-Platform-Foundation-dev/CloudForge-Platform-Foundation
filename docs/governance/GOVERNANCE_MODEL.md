# Governance Model

> Sprint 4 — CloudForge Platform Foundation
> สถานะ: Draft สำหรับ review
> เอกสารนี้กำหนดว่า "ใครตัดสินใจอะไร" และ "อะไรต้องถูกวัด/รายงาน" ในระดับแพลตฟอร์ม
> เชื่อมโยงกับ `docs/adr/` (มี ADR-0009 แล้ว ณ 2026-08-02), `governance_metrics` ใน
> `CANONICAL_DATA_MODEL.md`, และรายการที่ยังไม่ตัดสินใจซึ่งสะสมมาจาก Sprint 1-3

---

## 1. เป้าหมายและขอบเขต

Governance ในที่นี้หมายถึงกลไก 4 อย่าง:
1. **การตัดสินใจ** — ใครมีสิทธิ์ตัดสินเรื่องอะไร และบันทึกไว้ที่ไหน (ADR process)
2. **การกำกับข้อมูล** — ข้อมูลอะไรเก็บได้/ต้องลบ/ใครเข้าถึงได้ (data governance)
3. **การควบคุมต้นทุน** — งบ Gemini API และ resource อื่นไม่ให้บานปลาย (cost governance)
4. **การวัดผลและรายงาน** — metric อะไรบ้างที่ต้อง track เพื่อพิสูจน์ว่าแพลตฟอร์มทำงานตามหลักการ

เอกสารนี้ใช้กับทุกแอปในเครือ (App 1, 2, 3) และทีมที่เกี่ยวข้อง (ทีม dev, ทีมขาย, ทีม implement)

## 2. Roles & Responsibilities (RACI ระดับแพลตฟอร์ม)

| กิจกรรม | ทีม Dev | ทีมขาย | ทีม Implement | เจ้าของแพลตฟอร์ม |
|---|---|---|---|---|
| ตัดสินใจสถาปัตยกรรม (ADR) | R | C | C | A |
| แก้ security bug | R/A | I | I | C |
| ตั้งค่า tenant ใหม่ (Setup Wizard) | C | I | R/A | I |
| Demo ให้ลูกค้า (App 3 โหมด Demo) | I | R/A | I | I |
| อนุมัติเปิดใช้ Live mode ให้ลูกค้า | C | I | R | A |
| กำหนด/ทบทวนงบ Gemini API | C | I | I | R/A |
| ทบทวน governance metrics รายรอบ | C | I | I | R/A |

(R = Responsible, A = Accountable, C = Consulted, I = Informed)

> หมายเหตุ: ทีมงานปัจจุบันมีขนาดเล็ก บาง role อาจเป็นคนเดียวกัน ตารางนี้มีไว้เพื่อความชัดเจน
> เมื่อทีมขยาย ไม่ใช่การบังคับแบ่งแผนกจริงตอนนี้

## 3. Decision-Making Process (ADR)

- ทุกการตัดสินใจที่กระทบสถาปัตยกรรมข้ามแอป (เช่น รายการ "สิ่งที่ยังไม่ตัดสินใจ" ใน
  README ของ Sprint ก่อนหน้า) ต้องบันทึกเป็น **ADR (Architecture Decision Record)**
  ใน `docs/adr/` ตามรูปแบบ: บริบท → ทางเลือกที่พิจารณา → การตัดสินใจ → ผลกระทบ
- สถานะปัจจุบัน (อัปเดต 2026-08-02): `docs/adr/` มี **ADR-0009 (Accepted)** แล้ว 1 ไฟล์
  ส่วน 6 ประเด็นที่เคยอยู่ในคิว Sprint 4 นี้ ถูกรวมเข้าระบบเลขทางการแล้วเป็น
  **ADR-0010 ถึง ADR-0015** (ดูตารางข้อ 3.1 ที่อัปเดตแล้ว) — ยังเป็นสถานะ **Proposed**
  ทั้งหมด คือแค่ "จองคิว" ไว้ ยังไม่มีไฟล์ ADR จริงตัวไหนเลยสักตัว
- ADR ที่เกี่ยวกับ security (เช่น รูปแบบ auth ระหว่างแอป) ต้อง cross-reference กับ
  `docs/security/SECURITY_MODEL.md`

### 3.1 คิว ADR ที่ต้องเปิด (อัปเดต 2026-08-02 — ใช้เลขทางการจาก `ADR_INDEX.md` แล้ว)

> ⚠️ เลขเดิม (ADR-001 ถึง ADR-006 แบบ 3 หลัก) **เลิกใช้แล้ว** — เพื่อไม่ให้ชนกับระบบเลข 4 หลัก
> ของ `ADR_INDEX.md` ที่เป็นทางการทั้ง repo ตารางนี้แสดงเลขเดิมไว้ในวงเล็บเพื่อ traceability
> เท่านั้น

| # (เลขทางการ) | (เลขเดิม) | ประเด็น | ความเร่งด่วน | เหตุผล |
|---|---|---|---|---|
| ADR-0010 | (เดิม ADR-001) | Firestore แยก instance ต่อ tenant หรือ instance เดียวแบ่ง collection/prefix | สูง | กระทบ isolation model ทั้งแพลตฟอร์ม |
| ADR-0011 | (เดิม ADR-002) | App 3 ต่อ Firestore จริงตั้งแต่ต้น หรือ mock-only ก่อน | กลาง | กระทบ timeline การพัฒนา |
| ADR-0012 | (เดิม ADR-003) | API ระหว่าง App 3 กับ App 1/2: REST หรือ Firestore listener | กลาง | กระทบ `API_CONTRACT.md` |
| ADR-0013 | (เดิม ADR-004) | `governance_metrics` เริ่มเก็บจริงเมื่อไหร่ | สูง | ผูกกับการแก้ security bug แอป 2 — ควรรอจนกว่าข้อ 4.1 (ล่าง) จะแก้เสร็จ |
| ADR-0014 | (เดิม ADR-005) | ชื่อสุดท้ายของ App 3 | ต่ำ | ไม่กระทบ technical แต่กระทบเอกสาร/การสื่อสารลูกค้า |
| ADR-0015 | (เดิม ADR-006) | ขอบเขตสิทธิ์ลูกค้าเห็นได้ใน Live mode (สถานะอย่างเดียว หรือเห็นข้อมูลดิบ) | สูง | กระทบทั้ง security model และ contract กับลูกค้า |

## 4. Data Governance

### 4.1 หลักการ
- ข้อมูลที่เก็บต้องมี **legal basis** และ **retention policy** ที่ config ได้ต่อ tenant
  (ไม่ hardcode — ตรงกับ backlog แอป 1)
- สิทธิ์เข้าถึงข้อมูลต้องยึด least privilege ตาม `SECURITY_MODEL.md` ข้อ 3.2
- ก่อนเปิด `governance_metrics` ให้เก็บข้อมูลจริง (ADR-0013) ต้องแก้ security bug ในแอป 2
  ให้เสร็จก่อน เพราะไม่งั้นจะเป็นการเก็บ metric บนฐานข้อมูลที่ยังรั่วอยู่ — governance
  ที่วัดผลจาก data ที่ไม่ปลอดภัยไม่มีความหมาย

### 4.2 Data Lifecycle
| ขั้นตอน | เจ้าของ | หมายเหตุ |
|---|---|---|
| Collection (รับข้อมูลจากลูกค้า) | App 1 | ต้องผ่าน PII edge case test |
| Processing/Storage | App 2 | ปัจจุบันยังเป็น in-memory — ยังไม่เข้าเกณฑ์ governance ได้จริง |
| Read-only consumption | App 3 | โหมด Live เท่านั้น ไม่มีสิทธิ์แก้ไข |
| Deletion (PDPA) | App 2 | ต้องมี endpoint ลบจริงตาม audit log — ยังเป็น backlog |

## 5. Cost Governance

- งบประมาณ Gemini API รวมทั้งโปรเจกต์: **~30,000-70,000 บาท**
- ต้องมี cost guardrail ระดับ code (rate limit / budget cap ต่อ tenant) ไม่ใช่แค่ monitor
  หลังเกิดเหตุ — ตรงกับ "Cost Guard test" ที่ยังค้างอยู่ในแอป 2
- แนะนำ threshold แจ้งเตือน 2 ระดับ: 70% ของงบ (แจ้งเตือนทีม), 90% ของงบ (พิจารณาจำกัด
  การใช้งานอัตโนมัติ) — รายละเอียด threshold ที่แน่นอนควรเปิดเป็น ADR แยกถ้ายังไม่มี
  ตัวเลขที่ตกลงกันชัดเจน

## 6. Change Management

- การเปลี่ยนแปลงที่กระทบ schema กลาง (`CANONICAL_DATA_MODEL.md`) หรือ contract
  (`API_CONTRACT.md`) ต้องผ่าน review ร่วมกันของแอปที่เกี่ยวข้องทุกแอป ก่อน merge
- การเปลี่ยน Firestore security rule ต้องมี test คู่กันเสมอ (เช่น อัปเดต assertion ใน
  `test-firestore-rules` เมื่อเปลี่ยน rule เป็น `if false`) — ห้าม merge rule change
  โดยไม่มี test รองรับ
- Breaking change ต่อ tenant ที่ใช้งานจริงแล้ว (Live mode) ต้องแจ้งล่วงหน้าและมี
  rollback plan

## 7. Metrics & Reporting

Metric ที่ควรอยู่ใน `GovernanceMetric` entity (ตาม `CANONICAL_DATA_MODEL.md`) และควรเริ่มเก็บ
**หลังจาก** แก้ security bug แอป 2 เสร็จ:

| Metric | วัตถุประสงค์ |
|---|---|
| จำนวน unauthorized access attempt ที่ถูกปฏิเสธ | ยืนยันว่า fail-closed rule ทำงานจริง |
| Gemini API spend ต่อ tenant ต่อเดือน | เทียบกับ cost guardrail |
| Audit log integrity check pass rate | ยืนยันว่า `userEmail` ตรงกับ auth token ทุกครั้ง |
| PDPA deletion request → completion time | วัด compliance response time |
| Cross-tenant isolation test pass rate | รันเป็นส่วนหนึ่งของ CI ทุกครั้งที่มี rule เปลี่ยน |

## 8. Review Cadence

- **รายสัปดาห์** (ช่วงที่ยังมี security bug ค้าง): ทบทวนสถานะ backlog แอป 2
- **รายเดือน**: ทบทวน ADR queue, cost governance, และ Sprint ถัดไปของ platform docs
- **ทุกครั้งที่เปิด tenant ใหม่**: ทบทวน data governance และสิทธิ์เข้าถึงเฉพาะ tenant นั้น

## 9. สถานะปัจจุบัน ณ Sprint 4 (Gap Analysis)

| กลไก governance | สถานะ |
|---|---|
| ADR process มีเอกสารนิยามแล้ว | 🟢 (เอกสารนี้) |
| ไฟล์ ADR จริง | 🔴 ยังไม่มีแม้แต่ไฟล์เดียว ทั้งที่มี 6 ประเด็นรอ |
| Cost guardrail ระดับ code | 🔴 ยังไม่มี (Cost Guard test ยังไม่ทำ) |
| Data governance lifecycle ครบ 4 ขั้นตอน | 🔴 ขั้น Deletion (PDPA) ยังไม่เสร็จ |
| Governance metrics เริ่มเก็บจริง | 🔴 ยังไม่เริ่ม — รอ ADR-0013 และรอแก้ security bug ก่อน |

## 10. Open Items

- [ ] เปิดไฟล์ ADR-0010 ถึง ADR-0015 ตามคิวในข้อ 3.1 (เลขทางการ)
- [ ] กำหนดตัวเลข threshold ที่แน่นอนสำหรับ cost guardrail (70%/90% เป็นข้อเสนอเบื้องต้น)
- [ ] ตัดสินใจว่า `governance_metrics` เริ่มเก็บจริงพร้อมกับการแก้ security bug แอป 2 เลย
      หรือรอให้แก้เสร็จสมบูรณ์ก่อน (เชื่อม ADR-0013)