# BorrowCircle

**A Campus Item Lending Platform — Mobile App + REST API + Admin Dashboard**

BorrowCircle is a full-stack platform where university students lend and borrow academic and project-related items (calculators, textbooks, lab equipment, sports gear) in a structured, trackable, and accountable way — replacing informal WhatsApp-group lending.

The repository contains **three systems** that work together:

| # | System | Folder | Technology | Runs on |
|---|--------|--------|------------|---------|
| 1 | **Mobile App (Frontend)** | `frontend/` | Flutter (Dart) | Android emulator / device |
| 2 | **Backend API** | `backend/` | Node.js + Express + PostgreSQL | `http://localhost:3000` |
| 3 | **Admin Dashboard** | `admin/` | React 19 + Vite | `http://localhost:5173` |

---

## 1. Project Overview

### The Problem
Students frequently need an item for only a few days but do not want to buy it. Today they rely on WhatsApp groups or personal contacts, which offer **no tracking, no accountability, and no record** of who has what, when it is due, or whether it came back.

### The Solution
BorrowCircle provides a complete lending workflow with proof-of-handover:

- **Peer-to-Peer lending** (student → student)
- **Peer-to-Group lending** (e.g. IoT Club, Robotics Club — items owned by a club)
- **Full loan workflow:** `Request → Approve → Handover → Return → Review`
- **Secure handover** with a one-time code / QR code
- **Dashboards** for active loans, overdue items, and requests

### Key Features

- Registration & login restricted to allowed college email domains
- List items (personal or group-owned) with photos
- Search and filter available items by keyword / category / condition
- Send borrow requests for specific date ranges
- Approve / reject requests (owner-side, plus admin override)
- QR code or one-time code for handover confirmation
- Return confirmation and overdue detection
- Reviews and star ratings after completed loans
- Active loans dashboard, "My Requests", "My Listings"
- In-app chat for loan coordination and admin support
- Camera / fingerprint login, calendar view of loan dates, notifications
- Admin dashboard for users, items, requests, loans, reviews, and support chats

---

## 2. The Three Systems (Detailed)

### 2.1 Frontend — Flutter Mobile App (`frontend/`)

The student-facing mobile application, built with **Flutter** and organised with the **MVVM** (Model–View–ViewModel) pattern and **Provider** state management.

**Architecture:**

```
View (Screen) → ViewModel (ChangeNotifier) → Repository → ApiClient → Express API
```

- `lib/main.dart` — composition root: builds the object graph (ApiClient, repositories, ViewModels) and runs the app
- `lib/app.dart` — `MaterialApp`, theme, named routes
- `lib/core/` — constants (API base URL, colors), `api_client.dart` (HTTP + token refresh), `app_exception.dart`
- `lib/data/` — models and repository implementations for every feature
- `lib/presentation/` — screens, viewmodels, widgets, theme, routes, utils

**Main screens:** splash, welcome/auth, home item feed, all items, item details, make request, add item, handover (QR display), QR scanner, return item, review, requests, loans, my listings, groups, chat, conversation list, notifications, calendar, tasks, map, profile, account.

**Main packages** (from `pubspec.yaml`): `http`, `provider`, `shared_preferences`, `image_picker`, `qr_flutter`, `mobile_scanner`, `table_calendar`, `add_2_calendar`, `google_maps_flutter`, `local_auth`, `intl`.

**How it talks to the backend:** every network call goes through `lib/core/network/api_client.dart`, which attaches the JWT, transparently refreshes an expired token on `401`, and maps HTTP errors to typed exceptions. The server address is a single constant:

```dart
// lib/core/constants/app_constants.dart
static const String baseUrl = 'http://10.0.2.2:5000';
```

| Target | Value to use |
|--------|--------------|
| Android emulator | `http://10.0.2.2:3000` (default — `10.0.2.2` = host machine's `localhost`) |
| iOS simulator | `http://localhost:5000` |
| Physical device | Your computer's LAN IP, e.g. `http://192.168.x.x:5000` |

> **Note:** the app expects port **3000**, while the backend's default is **3000** (see `backend/.env`). Align them — either set `PORT=3000` in `backend/.env` or change `baseUrl` to port `3000` — before running the app.

---

### 2.2 Backend — Node.js / Express REST API (`backend/`)

The single source of truth for all data, exposed as a REST API. Plain **Express 5** with **raw parameterized SQL** executed against PostgreSQL through the `pg` connection pool.

**Folder layout of `backend/src/`:**

| Folder | Responsibility |
|--------|----------------|
| `config/` | `config.js` (env access), `db.config.js` (PostgreSQL pool), `multer.config.js` (image uploads), `tokenConfig.js` (token expiry) |
| `routes/` | URL definitions per resource, mounted under `/api/*` in `app.js` |
| `controllers/` | HTTP layer: read `req`, call services, send JSON responses |
| `services/` | business logic and validation |
| `models/` | all SQL queries (`pool.query`) — the only files that touch the database |
| `middlewares/` | `auth.middleware.js` (`protect`, `restrictTo`), `error.middleware.js` |
| `utils/` | `appError.js` (typed HTTP errors), `emailValidator.js` (domain allow-list) |

**API surface** (mounted in `src/app.js`):

| Base path | What it covers |
|-----------|----------------|
| `/api/users` | register, login, logout, logout-all, refresh, `me` (get/update profile + avatar), change password |
| `/api/items` | list/search/filter items, `my` listings, get one, create/update/delete (image upload) |
| `/api/requests` | create request, `my` requests, `incoming` requests, get one, approve / reject / cancel |
| `/api/loans` | create loan from an approved request, `borrowing`, `lending`, get one, handover, return |
| `/api/reviews` | create review, `received`, `given`, reviews of a user, reviews of a loan |
| `/api/chats` | conversations: list `my`, start admin/loan conversation, get/send messages, mark read |
| `/api/admin` | admin-only: dashboard stats, users (list/detail/role/delete), items, requests (approve/reject), loans, reviews, support chats |
| `/health` | unauthenticated health check |

**Cross-cutting behaviour:**

- **Auth:** JWT access token (15 min) + refresh token (7 days). The access token is sent as an httpOnly cookie and is also accepted as `Authorization: Bearer <token>` (needed by the mobile app). Refresh tokens are stored **hashed** in the `refresh_tokens` table and can be revoked individually or per user.
- **Email rules:** registration is limited to the domains in `ALLOWED_EMAIL_DOMAINS` (`patancollege.edu.np`, `study.beds.ac.uk`); exact-domain matching blocks look-alikes.
- **Email sending:** Nodemailer with Gmail OAuth2 credentials from `.env` (verification / notification mails).
- **Uploads:** Multer disk storage into `backend/uploads/profile_pics/` and `backend/uploads/items_images/`, images only (jpg/png/gif/webp), 5 MB max per file, served statically at `/uploads/...`.
- **CORS:** allows the admin dev server (`localhost:5173`, `localhost:4173`) with credentials so the auth cookies travel with requests.
- **Logging:** `morgan` request logging. Errors funnel through a central error middleware returning `{ success: false, message }`.

---

### 2.3 Admin Dashboard — React Web App (`admin/`)

A browser dashboard for the team/moderators to oversee the whole platform. Built with **React 19 + Vite + React Router 7**, plain CSS with CSS variables (primary teal `#0F766E`), and `axios` configured `withCredentials` so the JWT cookies are sent automatically.

**Auth model:** login at `/login` sets the httpOnly cookies via the API; an axios interceptor calls `/api/users/refresh` once on a `401 TOKEN_EXPIRED` and retries; failure falls back to the login screen. Only accounts whose `users.role = 'admin'` can pass the `restrictTo('admin')` guard on every `/api/admin/*` route — regular users see an "Admins only" screen.

**Pages:**

| Route | What it does |
|-------|--------------|
| `/login` | Email + password sign-in (cookies) |
| `/dashboard` | Platform counters + newest users / items / requests / loans |
| `/users`, `/users/:id` | All accounts: search, role filter; change role, delete (blocked with loan history), view owned items |
| `/items`, `/items/:id` | All listings: search, category / condition / availability filters, delete |
| `/requests`, `/requests/:id` | All requests: status filter, **approve / reject** (admin override) |
| `/loans`, `/loans/:id` | All loans: stage / status filters; full record incl. handover code |
| `/reviews`, `/reviews/:id` | All reviews: rating filter, **delete** for moderation |
| `/support-chats`, `/support-chats/:id` | Conversations between users and admins only (private user-to-user chats are never listed) |

---

## 3. Tech Stack

| Layer | Technology |
|-------|------------|
| Mobile app | Flutter (Dart SDK ^3.13.4), Provider (MVVM) |
| Backend API | Node.js, Express 5 |
| Database | PostgreSQL (via `pg` connection pool) |
| Auth | JWT (httpOnly cookies) + bcrypt password hashing + refresh-token rotation |
| Admin panel | React 19, Vite 8, React Router 7, axios |
| File storage | Local disk (`backend/uploads/`) via Multer |
| Email | Nodemailer (Gmail OAuth2) |
| Design | Figma |
| Testing | Postman + manual testing |

---

## 4. System Requirements

### Software

| Component | Requirement |
|-----------|-------------|
| **Node.js** | 18 LTS or newer (backend + admin) |
| **npm** | 9+ (bundled with Node.js) |
| **PostgreSQL** | 14 or newer, running locally (or reachable over the network) |
| **Flutter SDK** | 3.13+ / Dart ^3.13.4 (mobile app) |
| **Android Studio** (or VS Code + Flutter extension) | for emulator/device builds |
| **Git** | to clone the repository |

### Hardware (minimum)

- 8 GB RAM (16 GB recommended — Android emulator + Node + browser)
- ~10 GB free disk space (SDKs, `node_modules`, build outputs)
- Internet access for `npm install` / `flutter pub get`

### Ports that must be free

| Port | Used by |
|------|---------|
| `3000` | Backend API (configurable via `PORT` in `backend/.env`) |
| `5173` | Admin dashboard (Vite dev server; `4173` for `vite preview`) |
| `5432` | PostgreSQL |
| `5000` | Port the Flutter app is configured to call (`app_constants.dart`) — keep the API and this value in sync |

---

## 5. How to Install

### Step 0 — Clone the repository

```bash
git clone <repository-url>
cd BorrowCircle
```

### Step 1 — Database (PostgreSQL)

1. Install PostgreSQL 14+ and make sure the service is running on port `5432`.
2. Create the database (any name, e.g. `BorrowCircle`):

```sql
CREATE DATABASE "BorrowCircle";
```

3. Create `backend/.env` (copy the existing one and adjust if needed):

```env
# Server
PORT=3000
NODE_ENV=development

# Database
DB_HOST=localhost
DB_USER=postgres
DB_PORT=5432
DB_PASSWORD=<your-postgres-password>
DB_NAME=BorrowCircle

# Allowed college email domains (comma separated)
ALLOWED_EMAIL_DOMAINS=patancollege.edu.np,study.beds.ac.uk

# JWT secrets (two DIFFERENT random values)
JWT_ACCESS_SECRET=<random-64-char-string>
JWT_REFRESH_SECRET=<another-random-64-char-string>

# Nodemailer (Gmail OAuth2) settings
CLIENT_ID=<google-oauth-client-id>
CLIENT_SCERET=<google-oauth-client-secret>
REFRESH_TOKEN=<google-oauth-refresh-token>
EMAIL_USER=<gmail-address>
```

> **Security:** `.env` currently in the repo contains real credentials. Rotate the JWT secrets, database password, and Gmail OAuth values before any public deployment, and make sure `.env` stays out of commits (it is listed in `backend/.gitignore`).

### Step 2 — Backend API

```bash
cd backend
npm install
npm start          # nodemon server.js — starts on http://localhost:3000
```

The server connects to PostgreSQL **before** it starts listening (`server.js` awaits `connectDB()`), and exits with an error if the database is unreachable — so you will know immediately if the connection settings are wrong.

Apply the chat-system migration (adds the `role` column, `conversations` and `messages` tables; idempotent — safe to re-run):

```bash
node migrations/run.js migrations/add_chat_system.sql
```

Verify: open `http://localhost:3000/health` — you should see `{"status":"ok", ...}`.

### Step 3 — Admin Dashboard

```bash
cd admin
npm install
cp .env.example .env       # defaults: VITE_API_URL=http://localhost:3000/api
npm run dev                # http://localhost:5173
```

Promote yourself (or any account) to admin once the backend is running:

```sql
UPDATE users SET role = 'admin' WHERE id = <your user id>;
```

### Step 4 — Flutter Mobile App

```bash
cd frontend
flutter pub get
flutter run                # pick an Android emulator / connected device
```

Set the correct host in `frontend/lib/core/constants/app_constants.dart` before running:

```dart
static const String baseUrl = 'http://10.0.2.2:5000'; // Android emulator
// iOS simulator: http://localhost:5000
// Physical device: http://<your-LAN-ip>:5000
```

Remember to keep the port aligned with the backend's `PORT` (default `3000`) — either change this constant or set `PORT=5000` in `backend/.env`.

### Install in one glance

| System | Commands |
|--------|----------|
| Backend | `cd backend && npm install && npm start` |
| Admin | `cd admin && npm install && npm run dev` |
| Mobile | `cd frontend && flutter pub get && flutter run` |

---

## 6. Folder Structure

```
BorrowCircle/
├── README.md                     ← this file (main project documentation)
├── backend/                      ← SYSTEM 2: Node.js / Express REST API
│   ├── migrations/
│   │   ├── add_chat_system.sql   # idempotent SQL migration (roles, chats)
│   │   └── run.js                # migration runner: node migrations/run.js <file>
│   ├── src/
│   │   ├── app.js                # Express app: middleware, CORS, route mounting
│   │   ├── config/
│   │   │   ├── config.js         # central access to every env variable
│   │   │   ├── db.config.js      # PostgreSQL connection pool + connectDB()
│   │   │   ├── multer.config.js  # image upload storage & limits
│   │   │   └── tokenConfig.js    # access/refresh token expiry values
│   │   ├── controllers/          # user, item, borrowRequests, loan, review, chat, admin
│   │   ├── middlewares/          # auth (protect, restrictTo), error handler
│   │   ├── models/               # all SQL queries per table
│   │   ├── routes/               # route definitions mounted under /api
│   │   ├── services/             # business logic
│   │   └── utils/                # AppError, email validation
│   ├── uploads/                  # user-uploaded images (profile_pics, items_images)
│   ├── .env                      # environment variables (NOT for sharing)
│   ├── package.json
│   └── server.js                 # entry point: connect DB → listen on PORT
│
├── frontend/                     ← SYSTEM 1: Flutter mobile app (MVVM)
│   ├── lib/
│   │   ├── main.dart             # entry point: dependency injection + runApp
│   │   ├── app.dart              # MaterialApp, theme, named routes
│   │   ├── core/
│   │   │   ├── constants/        # app_constants (base URL), colors, static data
│   │   │   └── network/          # api_client.dart, app_exception.dart
│   │   ├── data/
│   │   │   ├── models/           # item, loan, request, review, user, chat...
│   │   │   ├── repositories/     # feature repositories (API implementations)
│   │   │   └── services/         # chat service
│   │   └── presentation/
│   │       ├── routes/           # app_routes.dart
│   │       ├── screens/          # all app screens (home, loans, chat, QR...)
│   │       ├── viewmodels/       # ChangeNotifier state holders per feature
│   │       ├── widgets/          # reusable UI components
│   │       ├── theme/            # app_theme.dart
│   │       └── utils/            # validators, formatting, receipts
│   ├── assets/                   # images & app icon
│   ├── test/
│   ├── pubspec.yaml              # Flutter dependencies
│   ├── API_DOCS.md               # REST API reference
│   ├── INTEGRATION.md            # how the app connects to the backend
│   └── README.md                 # frontend-specific docs
│
├── admin/                        ← SYSTEM 3: React admin dashboard
│   ├── src/
│   │   ├── api/                  # axios instance + endpoint modules (users, items...)
│   │   ├── components/
│   │   │   ├── layout/           # AdminLayout, ProtectedRoute
│   │   │   ├── ui/               # Button, Card, Table, Modal, Badge...
│   │   │   └── forms/            # UserRoleForm
│   │   ├── contexts/             # AuthContext
│   │   ├── hooks/                # useApi, useAuth, usePagination
│   │   ├── pages/                # Dashboard, Users, Items, Requests, Loans,
│   │   │                          # Reviews, SupportChats, Login
│   │   ├── styles/               # CSS variables + globals
│   │   ├── utils/                # helpers, formatting
│   │   ├── App.jsx, main.jsx, routes.jsx
│   ├── public/
│   ├── .env.example              # VITE_API_URL, VITE_APP_NAME
│   ├── package.json
│   └── vite.config.js
│
└── .git/ , .kilo/                # tooling folders
```

---

## 7. Database Connection

### How the backend connects

All database access is centralised in **`backend/src/config/db.config.js`**. It creates one `pg` `Pool` from environment variables and exports it; every model file imports that pool and runs parameterized queries (`pool.query(sql, values)`), so there is exactly one place where credentials and connection settings live.

```js
const pool = new Pool({
    host:     process.env.DB_HOST,
    user:     process.env.DB_USER,
    port:     process.env.DB_PORT,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
});
```

`server.js` calls `connectDB()` **before** `app.listen(...)`:

1. It borrows a client from the pool and runs a trivial connection test.
2. On success it logs `Connected to Database <DB_NAME>` and the HTTP server starts.
3. On failure it logs the error and **exits the process** (`process.exit(1)`) — the API never runs in a "half-connected" state.

Because it is a *pool*, concurrent requests reuse a small set of connections instead of opening one per request.

### Environment variables used for the connection

| Variable | Purpose | Example |
|----------|---------|---------|
| `DB_HOST` | PostgreSQL host | `localhost` |
| `DB_PORT` | PostgreSQL port | `5432` |
| `DB_USER` | Database user | `postgres` |
| `DB_PASSWORD` | User's password | `••••••` |
| `DB_NAME` | Database name | `BorrowCircle` |

These are read once in `src/config/config.js` and also used directly in `db.config.js`.

### Tables used by the application

| Table | Purpose |
|-------|---------|
| `users` | accounts: `full_name`, `email`, `password` (bcrypt hash), `role` (`user`/`admin`), `avatar`, timestamps |
| `items` | listings: `title`, `description`, `image_url`, `category`, `condition`, `owner_id`, `is_group_item`, `group_name`, `is_available` |
| `borrow_requests` | `item_id`, `requester_id`, `start_date`, `end_date`, `message`, `status` (pending / approved / rejected / cancelled) |
| `loans` | created from an approved request: `request_id`, `item_id`, `borrower_id`, `owner_id`, dates, `handover_code`, `handed_over_at`, `returned_at`, `status` (active / overdue / returned) |
| `reviews` | post-return ratings: `loan_id`, `reviewer_id`, `reviewee_id`, `rating`, `comment` |
| `conversations` | chat threads scoped to a loan, an item, or admin support (`participant1_id`, `participant2_id`) |
| `messages` | chat messages: `conversation_id`, `sender_id`, `text`, `is_read` |
| `refresh_tokens` | hashed refresh tokens with expiry and revocation flags |

### Migrations

The chat system was added through a migration script rather than table re-creation:

```bash
cd backend
node migrations/run.js migrations/add_chat_system.sql
```

- The SQL file is **idempotent** (`ADD COLUMN IF NOT EXISTS`, `CREATE TABLE IF NOT EXISTS`, guarded constraints), so running it twice changes nothing.
- It adds `users.role`, the `conversations` and `messages` tables, and a trigger that keeps `conversations.updated_at` current.

### Promoting an admin

```sql
UPDATE users SET role = 'admin' WHERE id = <your user id>;
```

### Query safety notes

- Every query in `src/models/*` uses **parameterized placeholders** (`$1, $2, ...`) — values are never concatenated into SQL strings, which protects against SQL injection.
- Search input is passed as a bound parameter (e.g. `'%' || $1 || '%'` combined with `ILIKE`), not string-interpolated.
- Loan creation re-checks `br.status = 'approved'` inside the `INSERT ... SELECT`, so a race between two simultaneous approvals cannot create duplicate loans.

---

## 8. Team

| Role | Responsibility |
|------|----------------|
| **Nabin Dhakal (cpnabin)** — Frontend | UI design (Figma) + Flutter app |
| **Melan Parajuli (MELAN-PARAJULI7)** — Backend | Database + REST APIs |
| **Shulabh Shah (Shulabh-bit)** — Testing & Docs | Testing, report, presentation |

## 9. Project Timeline

- **Start:** November 2026
- **Deadline:** 5 December 2026

## 10. License

This project is developed for academic purposes only.

---

**BorrowCircle** — Making campus sharing simple, safe, and accountable.
