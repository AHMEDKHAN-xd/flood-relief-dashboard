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
```

---

## 🐙 How to Put This Project on Your GitHub

You can push all project code, commits, and assets to your own GitHub account in **3 easy steps**:

### Method 1: Using the Included Push Script (Fastest)

1. Create a new repository on [GitHub](https://github.com/new) (e.g., `reliefhub` or `flood-relief-dashboard`). **Leave it empty** (do not check "Add README" or ".gitignore").
2. Run this command in the project directory, replacing with your GitHub URL:
```bash
./push_to_github.sh https://github.com/<YOUR-GITHUB-USERNAME>/reliefhub.git
```
Enter your GitHub username and Personal Access Token (or SSH credentials) when prompted.

---

### Method 2: Standard Git Commands

If you prefer to run git commands manually:

#### Step 1: Initialize Git and configure your identity
```bash
git init -b main
git config user.name "Your Name"
git config user.email "your.email@example.com"
```

#### Step 2: Stage and commit all files
```bash
git add .
git commit -m "feat: Initial commit of ReliefHub Flood Relief Platform"
```

#### Step 3: Link to your GitHub repository and push
```bash
# Using HTTPS:
git remote add origin https://github.com/<YOUR-GITHUB-USERNAME>/reliefhub.git
git push -u origin main

# OR using SSH (if you have SSH keys configured on GitHub):
git remote add origin git@github.com:<YOUR-GITHUB-USERNAME>/reliefhub.git
git push -u origin main
```

> **Note on GitHub Authentication**: When pushing via HTTPS, GitHub requires a **Personal Access Token (classic or fine-grained)** with `repo` scope instead of your account password. You can generate one at **GitHub Settings $\rightarrow$ Developer Settings $\rightarrow$ Personal Access Tokens**.

---

## 🚀 Step-by-Step Production Deployment Guide

ReliefHub is a unified full-stack application (React frontend + Express API + JSON database). Choose the deployment platform that best suits your needs:

---

### Option A: Render.com (Easiest & Recommended)
Render provides free and low-cost Web Services with automated GitHub integration and continuous deployment.

1. **Push your code to GitHub** (following the instructions above).
2. Go to [Render.com](https://dashboard.render.com/) and sign in.
3. Click **"New +"** $\rightarrow$ **"Web Service"**.
4. Connect your GitHub repository (`reliefhub`).
5. Configure the service settings:
   - **Name**: `reliefhub`
   - **Region**: Choose the closest region (e.g., Singapore or Frankfurt for South Asia).
   - **Branch**: `main`
   - **Runtime**: `Node`
   - **Build Command**:
     ```bash
     npm ci && npm run build
     ```
   - **Start Command**:
     ```bash
     npm start
     ```
   - **Plan**: `Free` or `Starter`
6. Add **Environment Variables** (in the "Environment" tab):
   - `NODE_ENV` = `production`
   - `PORT` = `3000`
7. Click **"Create Web Service"**. Render will build the Vite bundle, mount Express, and provision your live HTTPS URL (e.g., `https://reliefhub.onrender.com`).
8. *(Optional for Persistence on Starter plan)*: Add a **Disk** under the Disks tab mounted at `/app/data` with size `1 GB`.

---

### Option B: Railway.app
Railway offers zero-configuration Node.js hosting with persistent storage volumes.

1. Go to [Railway.app](https://railway.app/) and sign in with GitHub.
2. Click **"New Project"** $\rightarrow$ **"Deploy from GitHub repo"**.
3. Select your `reliefhub` repository.
4. Go to **Settings**:
   - Build Command: `npm run build`
   - Start Command: `npm start`
5. Go to **Variables**:
   - `NODE_ENV` = `production`
   - `PORT` = `3000`
6. Go to **Volumes** $\rightarrow$ **Add Volume**:
   - Mount path: `/app/data`
7. Click **"Generate Domain"** under the Networking tab to get your public HTTPS URL.

---

### Option C: Docker & Docker Compose
A multi-stage, hardened `Dockerfile` and `docker-compose.yml` are already included in the root directory.

#### Running with Docker Compose:
```bash
# Build and start the container in detached mode
docker compose up -d --build

# View logs
docker compose logs -f

# Verify running container
docker ps
```
The application will be accessible at `http://localhost:3000`, with database mutations persisted in the `./data` folder on the host machine.

#### Running with plain Docker:
```bash
# Build production image
docker build -t reliefhub:latest .

# Run container with volume mount for data
docker run -d \
  --name reliefhub \
  -p 3000:3000 \
  -v $(pwd)/data:/app/data \
  -e NODE_ENV=production \
  reliefhub:latest
```

---

### Option D: Google Cloud Run
Google Cloud Run provides serverless container execution with auto-scaling to zero.

1. Install and authenticate the Google Cloud SDK:
   ```bash
   gcloud auth login
   gcloud config set project <YOUR-GCP-PROJECT-ID>
   ```
2. Build and deploy directly from source using Google Cloud Build:
   ```bash
   gcloud run deploy reliefhub \
     --source . \
     --platform managed \
     --region asia-south1 \
     --allow-unauthenticated \
     --port 3000 \
     --set-env-vars NODE_ENV=production
   ```
3. Cloud Run will build the Docker container and output your live `run.app` service URL.

---

### Option E: Linux VPS / Ubuntu Server
For dedicated instances on DigitalOcean, Linode, AWS EC2, or Hetzner.

#### 1. Setup Node.js 20 & PM2
```bash
sudo apt update && sudo apt install -y curl git nginx
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install -g pm2
```

#### 2. Clone and Build Project
```bash
cd /var/www
sudo git clone https://github.com/<YOUR-USERNAME>/reliefhub.git
cd reliefhub
sudo npm ci
sudo npm run build
```

#### 3. Start with PM2 Process Manager
```bash
pm2 start server.ts --name "reliefhub" --interpreter tsx --env NODE_ENV=production,PORT=3000
pm2 save
pm2 startup
```

#### 4. Configure Nginx Reverse Proxy
Edit `/etc/nginx/sites-available/reliefhub`:
```nginx
server {
    listen 80;
    server_name relief.yourdomain.org;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```
Enable the site and reload Nginx:
```bash
sudo ln -s /etc/nginx/sites-available/reliefhub /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

#### 5. Secure with Free Let's Encrypt SSL
```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d relief.yourdomain.org
```

---

### Option F: Vercel Notes
If deploying to Vercel:
- Vercel is designed for serverless architectures with read-only filesystems. Since ReliefHub utilizes an in-process Mutex database writing to `data/reliefhub-db.json`, deploying to Vercel requires storing state in an external database (e.g., PostgreSQL, Supabase, or Redis) or configuring a serverless function adapter in `/api`.
- For standard full-stack Node.js servers, **Render**, **Railway**, **Cloud Run**, or a **VPS** (Options A–E) are strongly recommended.

---

## 🧪 Automated Verification Test Suite

ReliefHub includes a comprehensive, dual-layer automated test suite:

1. **`tests/backend.test.ts`**: Validates the 20 core business, relational, and concurrency invariants directly against the server-side API and database mutex.
2. **`tests/e2e-exhaustive.test.ts`**: Runs 45 end-to-end integration cycles testing all API CRUD methods, role enforcement, status transitions, and error handling.

To execute the test suite:
```bash
npm test
```

### Sample Output:
```
====================================================
Running ReliefHub Automated Verification Test Suite
====================================================
[PASS] TEST 1: Camp capacity: capacity 100 & 100 families results in Full status
[PASS] TEST 2: Camp validation: negative families, non-positive capacity, exceeding capacity rejected
[PASS] TEST 3: Low stock: item with stock 10 and reorder level 10 is flagged as Low Stock
[PASS] TEST 4: Dispatch stock validation: stock 10, requested 11 rejected, leaves stock unchanged
[PASS] TEST 5: Need reservation: req 20, fulfilled 5, pending 8 -> max additional reservation is 7
[PASS] TEST 6: Duplicate reservation: concurrent requests each reserving 7 on capacity 10 -> at most one succeeds
[PASS] TEST 7: Delivery: a valid dispatch of quantity 5 increases fulfilment by 5 exactly once
[PASS] TEST 8: Duplicate delivery: delivering the same dispatch again is rejected without corrupting fulfilment
[PASS] TEST 9: Cancellation: Pending dispatch of 4 restored 4 units of stock exactly once
[PASS] TEST 10: Cancellation restrictions: cancelling a Delivered dispatch is rejected
[PASS] TEST 11: In-kind donation: 10 units increases correct inventory item by 10 exactly once
[PASS] TEST 12: Cash donation: recording a cash donation does not change inventory
[PASS] TEST 13: Volunteer assignment: volunteer already assigned to Camp A cannot be assigned to Camp B
[PASS] TEST 14: Closed camp: a volunteer cannot be assigned to a Closed camp
[PASS] TEST 15: Critical gaps: High-priority at 39% appears; High-priority at exactly 40% does not appear
[PASS] TEST 16: Dashboard consistency: KPIs and category chart update after relevant mutations
[PASS] TEST 17: Persistence: Created record persists to disk and reloads cleanly
[PASS] TEST 18: API errors: invalid IDs, malformed inputs, and illegal transitions return proper errors
[PASS] TEST 19: Seed integrity: verify record counts and relationships in pristine seed data
[PASS] TEST 20: Role enforcement: restricted operations require Admin role
====================================================
Test Execution Summary: 20/20 PASSED
====================================================
EXHAUSTIVE TEST SUITE COMPLETED: 45/45 PASSED
====================================================
```

---

## 📡 REST API Documentation

All API routes are served under `/api` and return standardized JSON responses.

### Operational Endpoints
| Method | Route | Description | Role Required |
| :--- | :--- | :--- | :--- |
| `GET` | `/api/health` | System status, database health, record counts | Any |
| `GET` | `/api/dashboard/summary` | Aggregate KPI statistics for operations | Any |
| `GET` | `/api/dashboard/category-fulfilment`| Fulfilment percentage across 7 supply categories | Any |
| `GET` | `/api/dashboard/critical-gaps` | Needs where priority is High & fulfilment < 40% | Any |
| `GET` | `/api/dashboard/smart-recommendations`| Prioritized decision recommendations with stock & need checks | Any |
| `GET` | `/api/dispatches/delays` | Alert list for dispatches pending/in-transit > 24h | Any |
| `GET` | `/api/camps` | List all camps (filters: `search`, `district`, `status`) | Any |
| `POST` | `/api/camps` | Create new relief camp | `admin` |
| `PATCH` | `/api/camps/:id` | Update family count or status | `admin` |
| `DELETE` | `/api/camps/:id` | Delete unreferenced camp | `admin` |
| `GET` | `/api/inventory` | List warehouse items (filter: `lowStockOnly`) | Any |
| `POST` | `/api/inventory` | Register new inventory item | `admin` |
| `PATCH` | `/api/inventory/:id` | Adjust available stock, reorder level, or daily usage | `admin` |
| `DELETE` | `/api/inventory/:id` | Delete unreferenced inventory item | `admin` |
| `GET` | `/api/needs` | Camp demands with reserved quantities & fulfilment % | Any |
| `POST` | `/api/needs` | Record urgent camp need | `admin` |
| `PATCH` | `/api/needs/:id` | Update demand quantity or priority | `admin` |
| `DELETE` | `/api/needs/:id` | Delete need (blocked if active dispatches exist) | `admin` |
| `GET` | `/api/dispatches` | Active and historical convoy dispatches | Any |
| `POST` | `/api/dispatches` | Schedule convoy (instantly deducts warehouse stock) | `admin` |
| `POST` | `/api/dispatches/:id/in-transit` | Mark convoy departing depot | `admin` |
| `POST` | `/api/dispatches/:id/deliver` | Mark convoy delivered (increments fulfilled count) | `admin` |
| `POST` | `/api/dispatches/:id/cancel` | Cancel convoy (restitutes stock to warehouse) | `admin` |
| `GET` | `/api/donations` | List contributions ledger | Any |
| `POST` | `/api/donations` | Record Cash (PKR) or In-Kind donation | `admin` |
| `GET` | `/api/volunteers` | List volunteer force (filter: `skill`, `assignedStatus`) | Any |
| `POST` | `/api/volunteers` | Register volunteer | `admin` |
| `POST` | `/api/volunteers/:id/assign` | Deploy volunteer to Open or Full camp | `admin` |
| `POST` | `/api/volunteers/:id/unassign`| Return volunteer to standby pool | `admin` |
| `POST` | `/api/admin/reset-seed` | Restore pristine Sindh baseline demonstration data | `admin` |
| `POST` | `/api/admin/run-tests` | Trigger live invariant verification test suite | Any |

---

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

---

## 📜 License & Humanitarian Dedication

This project is open-source and dedicated to the relief workers, volunteers, and disaster management teams supporting flood-affected communities across Sindh, Pakistan.
