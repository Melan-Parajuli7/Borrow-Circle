# BorrowCircle Admin

React dashboard for managing BorrowCircle: users, items, borrow requests,
loans, reviews and admin support chats.

Built with **Vite + React 19 + React Router 7**. Styling uses plain CSS with
CSS variables from the Flutter app's palette (primary teal `#0F766E`).

## Requirements

- The **BorrowCircle API** (`../server`) running on `http://localhost:3000`
- An account with `role = 'admin'` in the database (see below)

## Getting started

```bash
npm install
npm run dev        # http://localhost:5173
```

`npm run build` produces a production bundle in `dist/`, and
`npm run preview` serves it locally.

## Configuration

Copy `.env.example` to `.env` if you need to point somewhere else:

```env
VITE_API_URL=http://localhost:3000/api
```

## Promoting an admin

The dashboard is only reachable for users whose `role` column is `admin`:

```sql
UPDATE users SET role = 'admin' WHERE id = <your user id>;
```

Regular members who sign in see an "Admins only" screen instead of the
dashboard, and the API answers `403` for every `/api/admin/*` route.

## Pages

| Route | What it does |
|-------|--------------|
| `/login` | Email + password sign-in (cookies) |
| `/dashboard` | Platform counters + newest users/items/requests/loans |
| `/users` | All accounts: search, role filter, counters |
| `/users/:id` | Profile, role change, delete (blocked with loan history), owned items |
| `/items` | All listings: search, category/condition/availability filters, delete |
| `/items/:id` | Full item record, delete |
| `/requests` | All requests: status filter, **approve / reject** (admin override) |
| `/requests/:id` | Full request, approve / reject |
| `/loans` | All loans: stage / status filters |
| `/loans/:id` | Full loan incl. handover code (admin visibility) |
| `/reviews` | All reviews: rating filter, **delete** for moderation |
| `/reviews/:id` | Full review, delete |
| `/support-chats` | Conversations between users and admins only |
| `/support-chats/:id` | Thread view (read-only in this release) |

## How auth works

1. `POST /api/users/login` sets the JWT **httpOnly cookies**.
2. Every request uses `withCredentials`, so cookies travel automatically
   (CORS is enabled on the API for this origin).
3. When the API answers `401` with `code: "TOKEN_EXPIRED"`, the axios
   interceptor calls `POST /api/users/refresh` once and retries the request.
4. If refresh fails, the app falls back to the login screen.

Private user-to-user chats are never listed under support chats — only
conversations where an admin takes part.