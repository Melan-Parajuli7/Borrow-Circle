# BorrowCircle API — Reference

Base URL: `http://10.0.2.2:5000` (configured in `lib/core/constants/app_constants.dart`).

All JSON bodies unless noted. Errors return:
```json
{ "success": false, "message": "..." }
```
Validation errors may include an `errors` array.

The Dart side maps HTTP status codes to typed exceptions (`FetchDataException`,
`BadRequestException`, `UnauthorisedException`) via `core/network/api_client.dart`.

> The chat endpoints below still exist on the Express backend, but the app's
> conversation/chat feature now uses Firestore directly
> (`data/services/chat_service.dart`). Backend API contract is unchanged.

---

## Auth

### POST /users/register
Register a new user.

**Body**
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| full_name | string | ✅ | |
| email | string | ✅ | recognized campus domains |
| password | string | ✅ | |

**Success (201)**
```json
{ "success": true, "accessToken": "...", "refreshToken": "...", "user": { "id": 1, "fullName": "...", "email": "...", "role": "user" } }
```

### POST /users/login
Log in and receive access + refresh tokens.

**Body**
| Field | Type | Required |
|-------|------|----------|
| email | string | ✅ |
| password | string | ✅ |

**Success (200)** — same shape as register.

Demo mode: `nabin.dhakal@patancollege.edu.np` / `Nabin@123` works offline when the backend is unreachable.

### POST /users/logout
Log out. Tokens are cleared locally even if the server is unreachable.

### GET /users/me
Get the logged-in user profile. Requires `Authorization: Bearer <token>`.

**Success (200)**
```json
{ "success": true, "user": { "id": 1, "fullName": "...", "email": "...", "role": "user" } }
```

### POST /users/refresh
Refresh the access token using the refresh token.

---

## Items

### GET /items
List items (searchable, filterable, paginated).

**Query**
| Field | Type | Notes |
|-------|------|-------|
| search | string | |
| category | string | |
| condition | string | new, like_new, good, fair, poor |
| available | boolean | |
| page | int | default 1 |
| limit | int | default 10 |

**Success (200)** — `{ "success": true, "data": [ {...item} ], ...pagination }`

### GET /items/my
Items listed by the current user.

### GET /items/:id
Single item detail.

**Success (200)** — `{ "success": true, "item": { ...item } }`

### POST /items
Create a listing (multipart: fields + `image` file).

**Body fields**
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| title | string | ✅ | |
| description | string | ❌ | |
| category | string | ❌ | |
| condition | string | ❌ | default `good` |
| is_group_item | boolean | ❌ | |
| group_name | string | ❌ | |

### PUT /items/:id
Update a listing (multipart).

### DELETE /items/:id
Delete a listing.

**Success (200)** — `{ "success": true, "message": "Item deleted" }`

---

## Borrow Requests

### GET /requests
### GET /requests/my
Requests sent by the current user.

### GET /requests/incoming
Requests received for the current user's items.

### POST /requests
Send a borrow request (desired borrow dates, up to 30 days).

### PATCH /requests/:id
Owner approves or declines a pending request.

### DELETE /requests/:id
Cancel/delete a request.

---

## Loans

### GET /loans
### GET /loans/borrowing
Active loans where the current user is the borrower.

### GET /loans/lending
Active loans where the current user is the lender.

### POST /loans
Item handover verification (QR code / confirmation code).

### PUT /loans/:id
Return an item (condition, return status).

---

## Reviews

### GET /reviews
### GET /reviews/received
Reviews received for the current user's items.

### GET /reviews/given
Reviews given by the current user.

### GET /reviews/user
Reviews for a specific user.

### POST /reviews
Leave a rating + review after a completed loan.

---

## Chats (backend API — not used by the Flutter chat UI)

### GET /chats/my
Current user's conversations.

### GET /chats/:id/messages
Messages of a conversation.

### POST /chats/:id/messages
Send a message.

### POST /chats/:id/read
Mark a conversation as read.

Real-time chat in the app is powered by Firestore instead — see `INTEGRATION.md` and `data/services/chat_service.dart`.

---

## Item object

```json
{
  "id": 1,
  "ownerId": 1,
  "ownerName": "...",
  "title": "Textbook",
  "description": "...",
  "category": "Books",
  "condition": "good",
  "isAvailable": true,
  "isGroupItem": false,
  "imageUrl": "...",
  "createdAt": "2026-11-20T10:00:00.000Z"
}
```

---

## Status codes

| Code | Meaning |
|------|---------|
| 200 | OK |
| 201 | Created |
| 400 | Validation / bad request |
| 401 | Unauthorized (missing or invalid token) |
| 404 | Not found |
| 500 | Server error |

## Environment variables (backend)

| Variable | Default | Notes |
|----------|---------|-------|
| PORT | 5000 | Backend HTTP port |
| JWT_SECRET | (required) | **change in production** |
| JWT_EXPIRES_IN | 7d | access token expiry |
