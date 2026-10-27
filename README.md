# ReliefHub — Flood Relief Coordination Platform
> **Sindh, Pakistan Provincial Disaster Response Command Center**  
> *A full-stack, mission-critical humanitarian logistics platform managing relief camps, inventory reservations, convoy dispatches, aid donations, and volunteer deployments.*

[![Tests](https://img.shields.io/badge/tests-45%2F45%20passed-emerald)](https://github.com)
[![React](https://img.shields.io/badge/Frontend-React%2019%20%7C%20Vite%208-blue)](https://react.dev)
[![Backend](https://img.shields.io/badge/Backend-Node.js%20%7C%20Express-teal)](https://expressjs.com)
[![Styling](https://img.shields.io/badge/Styling-Tailwind%20CSS%20v4-38bdf8)](https://tailwindcss.com)
[![Architecture](https://img.shields.io/badge/Data-Persistent%20Atomic%20Mutex-amber)](https://github.com)

---

## 📌 Table of Contents
1. [Overview & Humanitarian Context](#-overview--humanitarian-context)
2. [Key Capabilities & Features](#-key-capabilities--features)
3. [Design System (Executive Palette D)](#-design-system-executive-palette-d)
4. [Architecture & Concurrency Invariants](#-architecture--concurrency-invariants)
5. [Quick Start (Local Development)](#-quick-start-local-development)
6. [How to Put This Project on Your GitHub](#-how-to-put-this-project-on-your-github)
7. [Step-by-Step Production Deployment Guide](#-step-by-step-production-deployment-guide)
   - [Option A: Render.com (Easiest Full-Stack Free Tier)](#option-a-rendercom-easiest--recommended)
   - [Option B: Railway.app (Instant with Volume Persistence)](#option-b-railwayapp)
   - [Option C: Docker & Docker Compose](#option-c-docker--docker-compose)
   - [Option D: Google Cloud Run](#option-d-google-cloud-run)
   - [Option E: Linux VPS / Ubuntu (PM2 + Nginx + SSL)](#option-e-linux-vps--ubuntu-server)
   - [Option F: Vercel](#option-f-vercel-notes)
8. [Automated Verification Test Suite](#-automated-verification-test-suite)
9. [REST API Documentation](#-rest-api-documentation)
10. [Role-Based Access Control (RBAC)](#-role-based-access-control-rbac)
11. [Project Directory Layout](#-project-directory-layout)

---

## 🌊 Overview & Humanitarian Context

In Sindh, Pakistan, seasonal monsoon floods submerge key agricultural riverine corridors (Dadu, Badin, Larkana, Sukkur, Thatta, Mirpur Khas), displacing tens of thousands of families. 

**ReliefHub** was engineered as an authoritative operational command center for humanitarian coordinators (PDMA Sindh, NDMA, frontline NGOs) to solve critical failure points:
- **Zero Double-Allocation of Relief Aid**: Stock is atomically reserved the moment a dispatch convoy is registered, eliminating the risk of promising the same tents or ration packs to multiple flood camps.
- **Rule-Based Smart Priority Scoring**: Transparent decision support highlighting high-urgency camp shortages with low fulfilment percentages.
- **Supply Runway Forecasting**: Real-time projection of warehouse inventory runout days based on daily consumption rates.
- **Logistics Turnaround Delay Tracking**: Automated alerts flagging convoy dispatches stuck in pending or in-transit states past operational thresholds (>24 hours).
- **Audit-Ready Situation Reports (SITREP)**: 1-click printable PDF and CSV exports for provincial task forces and donor debriefs.

---

## ✨ Key Capabilities & Features

| Module | Core Functionality |
| :--- | :--- |
| **Operations Command (Overview)** | Real-time provincial telemetry, active camp occupancy load bars, critical shortage alerts (<40% fulfillment), rule-based Smart Recommendations, and instant Situation Report generator. |
| **Relief Camps Directory** | Directory of verified shelters across Sindh districts with real-time family counts, capacity enforcement (`families <= capacity`), and automated status transitions (`Open` $\leftrightarrow$ `Full` $\leftrightarrow$ `Closed`). |
| **Warehouse Inventory** | Central logistics stockpile tracking, reorder alert thresholds, estimated daily consumption rates, and days-of-supply runway indicators. |
| **Camp Supply Needs** | Priority demand register (High/Medium/Low) tracking required vs delivered vs reserved items with direct dispatch allocation actions. |
| **Fleet & Dispatches** | Convoy scheduling with instant stock deduction upon creation, in-transit telemetry, single-click delivery fulfillment, and safe stock restitution upon cancellation. |
| **Contributions & Ledger** | Financial cash grants (PKR) recorded strictly to ledger without contaminating physical stock; in-kind relief consignments atomic inventory replenishment. |
| **Volunteer Personnel** | Deploy doctors, logistics coordinators, drivers, and counselors to camps with mutual exclusivity (a volunteer cannot be in two camps simultaneously). |
| **Automated Invariant Runner** | In-app live test runner validating 20 core business logic constraints and relational consistency rules directly against the live backend. |

---

## 🎨 Design System (Executive Palette D)

ReliefHub adheres to the **Executive Command Center** design standard, engineered for calm clarity under emergency pressure:

- **Primary Charcoal Navy**: `#202B3C` (Headers, command bars, primary action buttons)
- **Secondary Deep Navy**: `#172232` (Sidebar command background, hero banner background)
- **Sidebar Hover / Active**: `#29384B` / `#344354`
- **Muted Antique Gold Accent**: `#D6A85F` (Selected page indicators, high-priority highlights, icon trims)
- **Soft Gold Highlight**: `#E8C98E`
- **Warm Executive Canvas**: `#F6F3ED` (Page background)
- **Card Background**: `#FFFFFF` with warm borders (`#E5E1D9`)
- **Primary Text**: `#263242` | **Secondary Text**: `#697586`
- **Semantic Indicators**: Accessible Red (Critical gaps), Accessible Amber (Low stock / Warning), Accessible Emerald (Delivered / Safe).

---

## 🏛️ Architecture & Concurrency Invariants

```
+-------------------------------------------------------------+
|                React 19 + Vite 8 SPA Client                 |
|     (Tailwind CSS v4 · Lucide Icons · Recharts · Motion)    |
+-------------------------------------------------------------+
                              |
                     HTTP / JSON (REST)
                              |
+-------------------------------------------------------------+
|               Express.js Full-Stack Server                  |
|    - Vite Middleware in Dev                                 |
|    - Static dist/ server in Production                      |
|    - /api Router (Camps, Needs, Stock, Dispatches, Ledger)  |
|    - Role Validation Middleware (x-user-role)               |
+-------------------------------------------------------------+
                              |
+-------------------------------------------------------------+
|            Persistent Database & Concurrency Mutex          |
|    - FIFO Async Mutex: Prevents double-allocation races     |
|    - Atomically persists to: data/reliefhub-db.json         |
|    - Clean fallback seed reinitialization                   |
+-------------------------------------------------------------+
```

### The 20 Business Invariants Enforced:
1. **Camp Capacity Cap**: Family population cannot exceed declared capacity. At 100% load, status automatically sets to `Full`.
2. **Camp Input Integrity**: Rejects negative numbers and non-positive capacity.
3. **Low Stock Detection**: Items where `stock <= reorder_level` are flagged immediately across all pages.
4. **Stock Reservation Gate**: Dispatches requesting more than current unreserved inventory are strictly rejected with HTTP 400.
5. **Need Reservation Ceiling**: Additional dispatches cannot exceed `required_quantity - fulfilled_quantity - active_reserved_quantity`.
6. **Concurrent Reservation Safety**: Simulated simultaneous requests over mutual capacity will only permit the first-come winner; the second is cleanly rejected with 400.
7. **Single-Action Delivery**: Delivering a dispatch increments fulfilled units exactly once and clears reservation.
8. **Idempotent Delivery Guard**: Duplicate delivery calls return an error without duplicating stock or fulfilment counts.
9. **Cancellation Restitution**: Cancelling a `Pending` or `In Transit` dispatch safely restores reserved inventory back to warehouse available stock.
10. **Delivery Irreversibility**: A `Delivered` dispatch can never be cancelled.
11. **In-Kind Stock Inflow**: In-kind donations increase physical stock atomically on the target warehouse item.
12. **Strict Cash Separation**: Monetary grants in PKR update the financial ledger and NEVER inflate physical warehouse inventory.
13. **Volunteer Mutual Exclusivity**: A volunteer already assigned to Camp A cannot be assigned to Camp B without first being unassigned.
14. **Closed Camp Protection**: Volunteers cannot be deployed to `Closed` camps.
15. **Critical Shortage Threshold**: High-priority needs with `< 40%` fulfillment are isolated into the Critical Shortages register.
16. **Provincial Summary Coherence**: Dashboard metrics strictly derive from ground data without mocked placeholders.
17. **File Persistence**: Every mutation commits to `data/reliefhub-db.json` and survives server restarts.
18. **RESTful Error Handling**: 400, 403, 404, and 409 status codes with actionable, typed error messages.
19. **Seed Re-initialization**: Clean baseline reset available via `/api/admin/reset-seed`.
20. **Role Enforcement**: Mutations require the `admin` role header (`x-user-role: admin`); `volunteer` mode is strictly read-only on administrative actions.

---

## ⚡ Quick Start (Local Development)

### Prerequisites
- **Node.js** (v18.0.0 or higher, Node 20+ recommended)
- **npm** or **bun** / **yarn**

### 1. Clone & Install Dependencies
```bash
git clone https://github.com/<your-username>/reliefhub.git
cd reliefhub
npm install
```

### 2. Start Development Server
```bash
npm run dev
```
Open **[http://localhost:3000](http://localhost:3000)** in your browser. The development server runs Express with integrated Vite middleware, hot module replacement, and live API endpoints.

### 3. Run Automated Invariant Tests
```bash
npm test
```
Executes all 45 automated unit, invariant, and E2E verification tests.

### 4. Build for Production
```bash
npm run build
npm start


## 👥 Role-Based Access Control (RBAC)

ReliefHub supports two primary operational personas, switchable at any time from the top header:

1. **Relief Coordinator (`admin`)**:
   - Full read/write authority across the entire provincial response.
   - Can create camps, adjust stock, schedule convoy dispatches, record donations, and deploy volunteers.
2. **Field Volunteer (`volunteer`)**:
   - Read-only operational field access to rosters, dispatches, and warehouse availability.
   - Administrative mutations return HTTP `403 Forbidden`.

To authenticate API requests, pass the header:
```http
x-user-role: admin
```

---

## 📁 Project Directory Layout

```
├── .dockerignore           # Production Docker ignore configuration
├── .env.example            # Environment variables template
├── .gitignore              # Git ignore rules
├── Dockerfile              # Production multi-stage Docker build
├── docker-compose.yml      # Local and self-hosted container orchestration
├── index.html              # HTML5 entry point with Plus Jakarta Sans & JetBrains Mono
├── metadata.json           # Applet manifest and capabilities
├── package.json            # Node.js project manifest and scripts
├── push_to_github.sh       # Automated GitHub repository push script
├── README.md               # Authoritative project documentation & deployment guide
├── server.ts               # Production-ready Express backend entry point
├── server/                 # Full-stack backend implementation
│   ├── db.ts               # Mutex-locked atomic JSON database layer
│   ├── seed-data.ts        # Pristine Sindh disaster baseline data
│   ├── routes/
│   │   └── api.ts          # Express REST API routes with RBAC enforcement
│   └── services/
│       └── reliefService.ts # Authoritative business logic, invariants & calculations
├── src/                    # React 19 Frontend SPA
│   ├── App.tsx             # Root application component and layout routing
│   ├── index.css           # Tailwind CSS v4 directives & Executive Palette D theme
│   ├── context/
│   │   └── AppContext.tsx  # Global state, role switching, toast notifications
│   ├── components/
│   │   ├── layout/         # Header, Navigation Sidebar, Topographic textures
│   │   ├── modals/         # Camp, Dispatch, Inventory, Need, SITREP, Volunteer modals
│   │   └── ui/             # KPI cards, Confirm dialogs, Skeletons, Toasts
│   ├── pages/              # Overview, Camps, Inventory, Needs, Dispatches, Ledger, Volunteers, Demo
│   ├── services/
│   │   └── api.ts          # Typed client-side API proxy
│   └── types/
│       └── index.ts        # Shared TypeScript data models and interfaces
└── tests/                  # Verification and Invariant test suites
    ├── backend.test.ts     # 20 core invariant verification tests
    └── e2e-exhaustive.test.ts # 45 exhaustive E2E integration tests
```
https://reliefhub-floodrelief-coordinationdashboard-3404.ai.studio/
---

## 📜 License & Humanitarian Dedication

This project is open-source and dedicated to the relief workers, volunteers, and disaster management teams supporting flood-affected communities across Sindh, Pakistan.
