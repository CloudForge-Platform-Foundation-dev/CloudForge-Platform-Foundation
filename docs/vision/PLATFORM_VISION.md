# Platform Vision — CloudForge Platform Foundation

> **หมายเหตุ:** ไฟล์นี้เคยมีเนื้อหาซ้ำกับ `PLATFORM_PRINCIPLES.md` ทั้งไฟล์ (คนละเรื่องกัน
> แต่ถูกวางเนื้อหาผิดไฟล์) แก้ไขแล้วเมื่อ 2026-08-02 — ดูหลักการปฏิบัติ (principles) ที่
> `PLATFORM_PRINCIPLES.md` แทน ไฟล์นี้พูดถึง**เป้าหมายและทิศทาง**เท่านั้น

---

## 1. Vision Statement

CloudForge มีเป้าหมายเป็น **Enterprise AI Operating Platform** — แพลตฟอร์มกลางที่ทุก AI
Studio ในเครือ (Ingest, Insight, Simulation, Deployment & Operations, Governance & Security)
ใช้ Foundation เดียวกัน แทนที่จะต่างคนต่างสร้างมาตรฐานของตัวเอง

*(อ้างอิงจาก `CLOUDFORGE_CONSTITUTION.md` ข้อ 11 และ `ROADMAP.md` — Long-Term Vision)*

## 2. Mission

ช่วยองค์กรสร้าง

- AI Applications
- Multi-Agent Systems
- Cloud Architecture
- Knowledge Platform
- Enterprise Automation

บน Foundation เดียวกัน เพื่อให้ทุก Studio ใช้งานร่วมกันอย่างเป็นมาตรฐาน ไม่ใช่ต่างระบบต่างมาตรฐาน

## 3. Goals

| เป้าหมาย | อธิบาย |
|---|---|
| Single Source of Truth | Repository เป็นแหล่งข้อมูลหลัก ไม่ใช่ chat history หรือ personal notes |
| Documentation First | ทุก Feature เริ่มจาก requirement/architecture ก่อนเขียนโค้ด |
| AI Native Architecture | AI เป็น core capability ไม่ใช่ feature เสริม |
| Security by Design | ออกแบบความปลอดภัยตั้งแต่ต้น ไม่ใช่เพิ่มทีหลัง |
| Enterprise Governance | ทุกการตัดสินใจสำคัญมี ADR รองรับ ตรวจสอบย้อนกลับได้ |

## 4. Strategic Direction

ทิศทางการพัฒนาแบ่งเป็นระยะตาม `ROADMAP.md`:

- **ระยะสั้น (v0.1–v0.3):** วางรากฐาน Repository, Governance, และ Core Platform Model
- **ระยะกลาง (v0.4–v0.8):** สร้าง AI Gateway, Agent Runtime, Workflow Engine, Security
  Platform, Developer Platform
- **ระยะยาว (v0.9–v1.0 และหลังจากนั้น):** เชื่อมทุก Studio เข้าด้วยกัน (Studio Integration)
  ไปสู่ Enterprise Release ที่รองรับ Multi-Cloud, Multi-Region, และ Marketplace ต่างๆ

ดูรายละเอียด version-by-version ที่ `ROADMAP.md` และดูสถานะ Studio จริง ณ ปัจจุบันที่
`PLATFORM_COMPONENTS.md` (ตาม ADR-0009)

## 5. What This Vision Is Not

เพื่อไม่ให้สับสนกับเอกสารอื่นในโฟลเดอร์เดียวกัน:

- **ไม่ใช่หลักการปฏิบัติที่บังคับใช้จริง** (ดู `PLATFORM_PRINCIPLES.md` แทน)
- **ไม่ใช่สถาปัตยกรรมระดับ component** (ดู `docs/architecture/`)
- **ไม่ใช่ roadmap ที่มี version/milestone ละเอียด** (ดู `ROADMAP.md`)

---

## Related Documents

- PLATFORM_PRINCIPLES.md
- CLOUDFORGE_CONSTITUTION.md
- ROADMAP.md
- docs/architecture/ENTERPRISE_ARCHITECTURE.md

---

End of Platform Vision
