# 🌍 GeoPay: Decentralized Spatial Regulatory Protocol

> **Sui Overflow 2026** · Nigeria 🇳🇬 · Tracks: **DeFi & Payments**

[![Sui](https://img.shields.io/badge/Built%20on-Sui-4CA2FF?style=for-the-badge)](https://sui.io)
[![Move](https://img.shields.io/badge/Language-Move-blueviolet?style=for-the-badge)](https://move-language.github.io)
[![Network](https://img.shields.io/badge/Network-Testnet-green?style=for-the-badge)](https://suiexplorer.com)
[![Walrus](https://img.shields.io/badge/Storage-Walrus-blue?style=for-the-badge)](https://walrus.site)
[![Version](https://img.shields.io/badge/Contract-V4-orange?style=for-the-badge)](https://suiexplorer.com)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)

---

## 📖 Introduction

**GeoPay** is a decentralized protocol designed to digitize and enforce professional land surveying standards on the **Sui blockchain**, developed by **Ahmed Omokunmi Muhammed** — a professional Surveyor and MSc candidate based in Nigeria — under the academic supervision and professional guidance of **Dr. (Surv.) Ayo Babalola**, a registered Surveyor and Head of Department of Land Surveying & Geo-informatics at the University of Ilorin.

> *While the blockchain is global, land administration is local.*

GeoPay digitizes the **Kwara State (Nigeria) Minimum Scale of Fees**, providing a replicable template for regulatory bodies worldwide to automate professional compliance and financial settlement on-chain.

---

## 🛠 The Problem (Nigerian Context)

In many emerging markets like Nigeria, the surveying industry faces critical challenges:

| Problem | Description |
| :--- | :--- |
| **Regulatory Compliance** | Difficult to track if surveyors adhere to SURCON/KW-GIS mandated fee scales( such as surveyor doing over chaging and undercutting for client |
| **Economic Leakage** | Government and professional bodies struggle to collect administrative dues efficiently |
| **Payment Trust** | The *"Red Copy"* (official survey document) is often withheld due to payment disputes |

---

## ✨ Features

### 1. 🔒 Milestone-Based Spatial Escrow
Using Sui's object model, the protocol **locks the survey fee** and only releases it once the **"Digital Red Copy"** is uploaded, verified, and approved by SURCON on-chain.

### 2. ⏰ prefer Time Lock
If the surveyor does not submit the survey document within **selected day**, the client automatically receives a **full refund** — no manual intervention needed.

### 3. 📁 Decentralized Document Storage (Walrus)
Survey documents in **any format** (DWG, DXF, PDF, AutoCAD, PNG, JPG) are stored permanently on **Walrus** — Sui's decentralized storage. The Blob ID is recorded on-chain permanently.

### 4. 🏛️ SURCON On-Chain Approval
The regulatory body (SURCON/NIS) reviews the uploaded document and approves it **directly on-chain** before payment is released — ensuring full regulatory compliance.

### 5. 💰 Automated Revenue Split
Instantly settles fees upon SURCON approval and client confirmation:
- **30%** → Surveyor
- **70%** → Regulatory Body (SURCON/NIS)

Ensuring **100% compliance** with professional tax requirements — zero manual intervention.

### 6. ⚖️ Dispute Resolution System
Either client or surveyor can raise a dispute. SURCON resolves it with a **custom percentage split** — protecting all parties fairly.

### 7. 💸 Excess Payment Refund
If the client overpays, the **excess is automatically refunded** immediately upon escrow creation.

---

## 📐 Official Fee Schedule (Kwara State, Nigeria)

All 20 tiers from the official **Kwara State Minimum Scale of Fees** are encoded on-chain:

| S/N | Land Area | Private Land (₦) | Commercial Land (₦) |
| :---: | :--- | ---: | ---: |
| 1 | 0 – 690 m² | 150,000 | 225,000 |
| 2 | >690 – 1,160 m² | 190,000 | 285,000 |
| 3 | >1,160 – 1,620 m² | 210,000 | 315,000 |
| 4 | >1,620 – 2,090 m² | 230,000 | 345,000 |
| 5 | >2,090 – 2,550 m² | 250,000 | 375,000 |
| 6 | >2,550 – 3,020 m² | 265,000 | 397,500 |
| 7 | >3,020 – 3,480 m² | 275,000 | 412,500 |
| 8 | >3,480 – 3,950 m² | 295,000 | 442,500 |
| 9 | >3,950 – 4,410 m² | 315,000 | 472,500 |
| 10 | >4,410 – 4,880 m² | 335,000 | 502,500 |
| 11 | >4,880 – 7,200 m² | 420,000 | 630,000 |
| 12 | >7,200 m² – 1 Ha | 505,000 | 757,500 |
| 13 | >1 Ha – 2 Ha | 580,000 | 870,000 |
| 14 | >2 Ha – 5 Ha | 665,000 | 997,500 |
| 15 | >5 Ha – 10 Ha | 750,000 | 1,125,000 |
| 16 | >10 Ha – 15 Ha | 835,000 | 1,252,500 |
| 17 | >15 Ha – 20 Ha | 920,000 | 1,380,000 |
| 18 | >20 Ha – 30 Ha | 995,000 | 1,492,500 |
| 19 | >30 Ha – 40 Ha | 1,060,000 | 1,590,000 |
| 20 | >40 Ha – 50 Ha | 1,145,000 | 1,717,500 |
| + | Above 50 Ha | +15,000/Ha | +22,500/Ha |

> 📄 Source: Official Kwara State Survey Fee Schedule Document

---

## 🏗 Technical Stack

| Layer | Technology |
| :--- | :--- |
| **L1 Blockchain** | Sui (Move Language) |
| **Smart Contract** | Move — Escrow, Approval & Dispute Resolution |
| **Document Storage** | Walrus (Decentralized — DWG, PDF, AutoCAD, any format) |
| **Frontend** | HTML/CSS/JavaScript + Sui Wallet Integration |
| **Target Jurisdiction** | Kwara State, Nigeria (Phase 1) |

---

## 📦 Deployed Contract

| Item | Value |
| :--- | :--- |
| **Network** | Sui Testnet |
| **Package ID (V5 — Current)** | `0x771247bed2dc43399ac0be195151c7c1922baab5429128a796228e5a463518d4` |
| **Upgrade Cap** | `0x2b2ec8688decab1c02a141fc3ca7f7bd286275ad766d5a0e7871f30cfc10563d` |
| **SURCON/NIS Address** | `0xf44f68ac7f90d87796c1e2d654be2b00651d25cf7ec83185519f8c939ff1307b` |
| **Module** | `geopay_escrow` |
| **Contract Version** | V4 — With SURCON approval, dispute resolution & Walrus storage |
| **Status** | ✅ Live |

### Contract Version History

| Version | Package ID | Features Added |
| :--- | :--- | :--- |
| V1 | `0xdce69a78...8818` | Basic escrow, 70/30 split |
| V2 | `0xcbbe6dac...13f8` | Document upload, fee tiers |
| V3 | `0xc1222e16...c2a7` | Time lock, Walrus storage |
| V4 | `0x537e7ab3...050d` | SURCON approval, dispute resolution, excess refund |

🔗 [View on Sui Explorer](https://suiexplorer.com/object/0x537e7ab3acddaa671530f588ed3e2c79e48acd8480e7bdbbaeba8548a3c3050d?network=testnet)

🌐 [Live Demo](https://geopay-dapp.vercel.app)

---

## 📂 Project Structure

```
GeoPay-Sui/
├── move_contracts/              # Sui Move smart contract
│   ├── sources/
│   │   └── geopay_escrow.move  # Main contract (V4)
│   └── Move.toml               # Package configuration
├── frontend/                   # Web dApp
│   └── geopay_live_v4.html     # Full frontend with wallet integration
├── docs/                       # Documentation
│   └── REFERENCE_NOTES.txt     # All IDs, commands & fee schedule
└── README.md                   # Project documentation
```

---

## 🚀 Getting Started

### Prerequisites
- [Sui CLI](https://docs.sui.io/guides/developer/getting-started/sui-install)
- [Git](https://git-scm.com)
- Sui Wallet browser extension

### Build
```bash
sui move build
```

### Test
```bash
sui move test
```

### Deploy
```bash
sui client publish --gas-budget 100000000
```

### Upgrade
```bash
sui client upgrade --gas-budget 100000000 \
  --upgrade-capability 0x2b2ec8688decab1c02a141fc3ca7f7bd286275ad766d5a0e7871f30cfc10563d
```

---

## 🔑 Key Contract Functions

| Function | Who Can Call | Description |
| :--- | :--- | :--- |
| `create_escrow` | Client | Create escrow (no time lock) |
| `create_escrow_v2` | Client | Create escrow with 7-day time lock |
| `submit_red_copy` | Surveyor | Submit document hash |
| `submit_red_copy_v2` | Surveyor | Submit with full Walrus metadata |
| `regulatory_approve` | SURCON/NIS | Approve document on-chain |
| `confirm_and_release` | Client | Release 70/30 payment after approval |
| `cancel_escrow` | Client | Cancel and get full refund (pending only) |
| `claim_expired_refund` | Client | Claim refund after deadline passes |
| `raise_dispute` | Client or Surveyor | Raise a dispute |
| `resolve_dispute` | SURCON/NIS | Resolve dispute with custom split |

---

## 📊 Contract States

```
PENDING → SUBMITTED → APPROVED → COMPLETED
   │           │
   │           └──► DISPUTED → COMPLETED (partial refund)
   │
   ├──► CANCELLED (client cancels manually)
   └──► EXPIRED (deadline passed, auto refund)
```

--- ### dapp_website :  

https://geopay-dapp.vercel.app/

## 👥 The Team

### Ahmed Omokunmi Muhammed — Developer & Lead Researcher
*Professional Surveyor | Site Officer*
*MSc Candidate — Surveying & Geo-informatics*
*Federal University of Technology, Minna (Alumnus)*
*Nigeria 🇳🇬*

Responsible for protocol design, smart contract development, frontend engineering, and all blockchain integration.

---

### Dr. (Surv.) Ayo Babalola — Academic Supervisor & Professional Adviser
*Ph.D. — Surveying & Geo-informatics*
*Registered Surveyor (SURCON)*
*Head of Department, Land Surveying & Geo-informatics*
*University of Ilorin, Nigeria 🇳🇬*

Providing academic supervision, professional domain expertise, and regulatory guidance to ensure GeoPay aligns with Nigerian surveying standards and SURCON requirements.

*Built with ❤️ for Sui Overflow 2026 — digitizing land administration, one block at a time.*
