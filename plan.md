# BorrowCircle — Project Plan

| | |
|---|---|
| **Project** | BorrowCircle — Campus Item Lending Application |
| **Institution** | Patan College for Professional Studies (PCPS) |
| **Based on** | Software Requirements Specification (SRS) v1.0 |
| **Plan version** | 1.0 |
| **Date** | 23 November 2026 |

---

## 1. Objective

Build BorrowCircle, an Android (Flutter) app plus REST backend that lets students
within a college community **list, discover, borrow, and return** items instead of
buying them. The system supports the full lending lifecycle: accounts, listings,
borrow requests, approvals, QR-verified handover, returns, ratings, and reporting.

---

## 2. Current State (Gap Analysis)

The repository already contains a **complete Flutter frontend** and an **empty
Node/Express backend skeleton**. The app currently builds and runs on a device.

| Layer | Location | Status |
|---|---|---|
| Flutter app (UI, state, services) | `lib/` | ✅ Complete |
| REST API contract (consumed by app) | `lib/services/` | ✅ Defined by the client |
| Express backend | `src/app.js` | ⚠️ Stub only (`express.json()` only) |
| Database | — | ❌ Not created yet |
| Auth (JWT + refresh cookies) | backend | ❌ Not implemented |
| Admin / reporting features | frontend | ❌ No screens yet (SRS FR-40–FR-44) |

**Key implication:** the backend must be built to satisfy the exact endpoints and
JSON shapes the frontend already calls (Section 5). Do **not** change the Flutter
side's request formats — implement the server to match them.

### 2.1 Hard Constraints (do not break the running build)

- **Do NOT modify** `android/` Gradle files, `gradle-wrapper`, `AndroidManifest`
  versions, `pubspec.yaml` version constraints, or `pubspec.lock`.
- **Do NOT run** `flutter pub upgrade` / change SDK (`sdk: ^3.13.4`).
- The app already builds with Flutter 3.47.2 at
  `C:\flutter_windows_3.47.2-stable\flutter\bin\flutter.bat`. Keep using it.
- Backend stays on the installed deps (`express`, `dotenv`, `nodemon`) plus a
  database driver added only when the DB phase starts.

---

## 3. Tech Stack

**Frontend (done):** Flutter 3.47.2 · Dart ^3.13.4 · Provider (state) · `http`
(REST + multipart) · `shared_preferences` (token persistence) · `image_picker` ·
`qr_flutter` · `intl`.

**Backend (to build):** Node.js · Express 5 · `dotenv` for config · a database
(choose in Phase 1 — SQLite for zero-setup dev, or MySQL/PostgreSQL).

**Auth model:** backend issues `accessToken` + `refreshToken` as cookies; the
Flutter `ApiService` stores them and auto-refreshes on 401 via `POST /users/refresh`.

---

## 4. Architecture

```
Flutter app (lib/)
  pages/  →  controller/ (Provider)  →  services/  →  api_service.dart
                                                        │ HTTPS /api
                                                        ▼
  Express backend (src/)  →  controllers → services → models → Database
```

- **Frontend flow:** `Page → Controller → Service → ApiService → Backend`.
- **Backend flow (to mirror):** `route → controller → service → model → DB`,
  returning the JSON keys the models expect.

---

## 5. Backend API Contract (must match the client)

All routes are under `/api`. The client sends cookies `accessToken`/`refreshToken`
and expects JSON with the exact keys below (from `lib/model/*`).

### 5.1 Users — `/api/users`
| Method | Path | Body | Response |
|---|---|---|---|
| POST | `/register` | `full_name`, `email`, `password` | `{ user }` + Set-Cookie tokens |
| POST | `/login` | `email`, `password` | `{ user }` + Set-Cookie tokens |
| POST | `/logout` | — | clears cookies |
| POST | `/refresh` | — | new `accessToken` cookie |
| GET | `/me` | — | `{ user }` |
| PUT | `/me` (multipart) | `full_name`, file field `avatar` | `{ user }` |

`user` = `{ id, full_name, email, role, avatar, created_at }`.

### 5.2 Items — `/api/items`
| Method | Path | Notes |
|---|---|---|
| GET | `/` | query: `search`, `category`, `condition`, `available`, `page`, `limit` → `{ items, page, limit, total, totalPages }` |
| GET | `/my` | my listings (same paging wrapper) |
| GET | `/:id` | `{ item }` |
| POST | `/` (multipart) | `title`, `description`, `category`, `condition`, `is_group_item`, `group_name`, file `image` → `{ item }` |
| PUT | `/:id` (multipart) | same fields + optional `is_available` → `{ item }` |
| DELETE | `/:id` | |

`item` = `{ id, title, description, image_url, category, condition, owner_id,
is_group_item, group_name, is_available, owner_name, owner_avatar, created_at }`.
`image_url` is returned as a server path like `/uploads/items_images/x.jpg`.

### 5.3 Requests — `/api/requests`
| Method | Path | Notes |
|---|---|---|
| POST | `/` | `item_id`, `start_date` (YYYY-MM-DD), `end_date`, `message?` → `{ request }` |
| GET | `/my` | requests I sent |
| GET | `/incoming` | requests for my items |
| GET | `/:id` | `{ request }` |
| PATCH | `/:id/approve` · `/reject` · `/cancel` | → `{ request }` |

`request` = `{ id, item_id, requester_id, owner_id, start_date, end_date, status,
message, item_title, item_image, requester_name, requester_avatar, owner_name, created_at }`.
`status` ∈ `pending | approved | rejected | cancelled`.

### 5.4 Loans — `/api/loans`
| Method | Path | Notes |
|---|---|---|
| POST | `/` | `request_id` (owner starts loan from an approved request) → `{ loan }` |
| GET | `/borrowing` | loans where I am borrower |
| GET | `/lending` | loans where I am owner |
| GET | `/:id` | `{ loan }` — **only here** the borrower receives `handover_code` |
| PATCH | `/:id/handover` | `code` (borrower's 6-digit) → `{ loan }` |
| PATCH | `/:id/return` | owner confirms return → `{ loan }` |

`loan` = `{ id, request_id, item_id, borrower_id, owner_id, start_date, end_date,
status, stage, handed_over_at, returned_at, item_title, item_image, borrower_name,
borrower_avatar, owner_name, owner_avatar, handover_code }`.
- `status` ∈ `active | returned | overdue`.
- `stage` (server-derived) ∈ `awaiting_handover | on_loan | overdue | returned`.
- `handover_code` is sent **only to the borrower** while `stage == awaiting_handover`.

### 5.5 Reviews — `/api/reviews`
| Method | Path | Notes |
|---|---|---|
| POST | `/` | `loan_id`, `rating` (1–5), `comment?` → `{ review }` (only after item returned) |
| GET | `/received` | reviews about me + summary |
| GET | `/given` | reviews I wrote |
| GET | `/user/:id` | public reviews of another user |

Response wrapper: `{ result: { summary: { total, average }, reviews: [...], page, limit, total, totalPages } }`.
`review` = `{ id, loan_id, reviewer_id, reviewee_id, rating, comment,
reviewer_name, reviewer_avatar, reviewee_name, item_title, created_at }`.

### 5.6 Groups
No backend group API. A "group" is just the `group_name` on group items; the
frontend (`GroupService`) derives groups from the items list. No extra endpoint needed.

---

## 6. Database Schema (derived from the models)

```
users        (id PK, full_name, email UNIQUE, password_hash, role, avatar,
              created_at)
items        (id PK, owner_id FK→users, title, description, image_url, category,
              condition, is_group_item, group_name, is_available, created_at)
requests     (id PK, item_id FK→items, requester_id FK→users, owner_id FK→users,
              start_date, end_date, status, message, created_at)
loans        (id PK, request_id FK→requests, item_id FK→items, borrower_id FK→users,
              owner_id FK→users, start_date, end_date, status, stage,
              handover_code, handed_over_at, returned_at, created_at)
reviews      (id PK, loan_id FK→loans, reviewer_id FK→users, reviewee_id FK→users,
              rating, comment, created_at)
-- reports (admin feature) -> added in Phase 5
   reports   (id PK, reporter_id FK→users, target_type, target_id, reason,
              status, created_at)
```

- Store `password` as a **hash** (bcrypt), never plain text (SRS NFR-04).
- Dates for requests/loans stored as `YYYY-MM-DD`; `created_at` as ISO timestamps.

---

## 7. Requirements → Status Mapping

Legend: ✅ done · 🟡 backend pending (frontend ready) · 🔴 missing everywhere.

### Functional
| ID | Requirement | Status |
|---|---|---|
| FR-01–05 | Registration, validation, unique email, secure credentials | 🟡 backend |
| FR-06–09 | Login/logout, credential check, protect routes | 🟡 backend |
| FR-10–12 | View/update profile, show to others | 🟡 backend (UI done) |
| FR-13–18 | Add/edit/delete listings, image, condition, availability | 🟡 backend (UI done) |
| FR-19–22 | Browse, search, filter by category, item details | 🟡 backend (UI done) |
| FR-23–28 | Borrow request, period, owner notify, approve/reject, conflict guard | 🟡 backend (UI done) |
| FR-29–33 | Active loans, borrowing/lending history, dates, confirm return | 🟡 backend (UI done) |
| FR-34–36 | Notifications (requests, decisions, updates) | 🔴 no notification system yet |
| FR-37–39 | Rate/review after completion, show on profile | 🟡 backend (UI done) |
| FR-40–44 | Reporting + admin (review, remove, manage, restrict) | 🔴 no frontend or backend |

### Non-Functional
| ID | Requirement | Approach |
|---|---|---|
| NFR-01–03 | Performance, concurrent users | pagination (already in API), indexes on FKs, stateless API |
| NFR-04–07 | Security | bcrypt hashing, JWT, auth middleware, input validation, HTTPS |
| NFR-08–10 | Usability | Material 3 theme, consistent nav (done in frontend) |
| NFR-11–12 | Reliability | DB transactions for request→loan→return, global error handler |
| NFR-13–14 | Maintainability | layered backend (route→controller→service→model), consistent style |

---

## 8. Phased Implementation Plan

### Phase 0 — Backend foundation
- Add DB driver + schema (Section 6); create DB connection module under `src/config/`.
- Add `json` body parsing (exists) + CORS for dev + static `/uploads` serving.
- Create folder layout: `src/{routes,controllers,services,models,middleware,utils}`.
- Add global error handler + `asyncHandler` wrapper.

### Phase 1 — Auth (FR-01–09, NFR-04–06)
- Register (validate, unique email, bcrypt), login, logout, refresh, me.
- JWT access + refresh cookies; `authMiddleware` to protect routes.
- Profile get/update with avatar upload (`multer`) → `/uploads/profile_pics/`.

### Phase 2 — Items (FR-13–22)
- CRUD + `GET /` with search/category/condition/available + pagination.
- `GET /my`, image upload → `/uploads/items_images/`.
- Ownership checks on update/delete.

### Phase 3 — Requests (FR-23–28)
- Create request (validate item available, borrower ≠ owner, ≤30 days).
- List my/incoming, get one, approve/reject/cancel with ownership checks.
- Conflict guard: block approve if another approved loan overlaps the period.

### Phase 4 — Loans + Handover + Return (FR-29–33)
- Owner creates loan from approved request; generate 6-digit `handover_code`.
- `stage` derivation; send `handover_code` only to borrower pre-handover.
- Handover (owner verifies code) and return; mark item available again.
- Use DB transaction; overdue detection for `stage == overdue`.

### Phase 5 — Reviews + Reporting + Admin (FR-37–44)
- Reviews after returned loan; rating summary aggregation.
- Reporting endpoints (report item/user).
- Admin role: list users, remove listings, review reports, suspend accounts.
- Restrict all admin routes to `role == 'admin'`.

### Phase 6 — Notifications (FR-34–36)
- Notification records + endpoints; in-app list on the Notifications screen.
- (Optional later) push notifications — listed as a future enhancement.

### Phase 7 — Testing & Hardening
- Unit tests for controllers/services; endpoint tests per section.
- Validate error shapes match `ApiService` expectations.
- Seed script for demo data.

---

## 9. Testing Plan
- **Backend:** per-endpoint tests (happy path + validation/permission failures).
- **Integration:** register → list item → request → approve → handover → return → review.
- **Frontend:** `flutter analyze` must stay clean; re-run on the SM A245F device.
- **Security checks:** duplicate email rejected, unauth access blocked, password hashed,
  owner-only mutations, admin-only admin routes.

---

## 10. Out of Scope (Future Enhancements, per SRS §8)
In-app chat · push notifications · QR handover (partially present) · advanced
search · location-based discovery · analytics · overdue reminders · ID verification ·
web admin dashboard · fraud prevention.

---

## 11. Definition of Done
- All SRS functional requirements (FR-01–FR-44) implemented or explicitly deferred.
- Backend returns exactly the JSON shapes in Section 5.
- App builds and runs unchanged on the device with no Gradle/version changes.
- Core lending lifecycle passes end-to-end testing.