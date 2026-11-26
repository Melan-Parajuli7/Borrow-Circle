# Integration Guide — Flutter ↔ Node/Express

This document explains how the BorrowCircle Flutter app connects to the Node.js
Express backend, end to end.

---

## 1. Network configuration

The base URL lives in a single constant:

**`lib/core/constants/app_constants.dart`**

```dart
static const String baseUrl = 'http://10.0.2.2:5000';
```

| Target | Value to use |
|--------|--------------|
| Android emulator | `http://10.0.2.2:5000` (default) |
| iOS simulator | `http://localhost:5000` |
| Physical device | Your computer's LAN IP, e.g. `http://192.168.x.x:5000` |

> `10.0.2.2` is the Android emulator's alias for the host machine's `localhost`.
> Make sure the backend is running on the same port before starting the app.

---

## 2. Dependency injection (wiring)

**`lib/main.dart`** assembles the object graph once:

1. `WidgetsFlutterBinding.ensureInitialized()`
2. `TokenStorage.load()` — restores persisted access/refresh tokens.
3. `ApiClient(http.Client())` — HTTP client that attaches the Bearer token and
   refreshes tokens on 401.
4. One repository implementation per feature (items, loans, requests, reviews,
   groups, chat, calendar, auth, account, fingerprint, notifications, password).
5. Every ViewModel is provided via `MultiProvider` (e.g.
   `ChangeNotifierProvider(create: (_) => ItemViewModel(itemRepository))`).
6. `runApp(const BorrowCircleApp())`.

This is the **Composition Root** — ViewModels depend on repository interfaces,
so an implementation can be swapped (e.g. a mock for tests) without touching
the UI.

---

## 3. Request flow (example: load items)

1. **View** (`HomeTab`) calls `viewModel.load()`.
2. **ViewModel** (`ItemViewModel.load`) sets `isLoading = true`, calls
   `_itemRepository.getItems(...)`.
3. **Repository** (`ItemRepositoryImpl.getItems`) calls
   `_apiClient.get(AppConstants.itemsEndpoint, query: {...})`.
4. **ApiClient** attaches `Authorization: Bearer <token>`, GETs the Express
   backend, throws a typed `AppException` on non-2xx.
5. Repository parses JSON into `ItemModel` (wrapped in `Paged` for lists).
6. ViewModel sets `isLoading = false`, notifies listeners → UI rebuilds.

The View never talks to the network directly — it only observes
the ViewModel and triggers actions.

---

## 4. Authentication & the Bearer token

- Tokens (access + refresh) are persisted in `SharedPreferences`
  (`core/constants/app_constants.dart`: `tokenKey`, `refreshTokenKey`).
- `TokenStorage` loads them before the first request so the splash screen can
  restore an existing session.
- `ApiClient` reads the token on every request and sends
  `Authorization: Bearer <token>`; on 401 it attempts a token refresh.
- `AuthViewModel.isLoggedIn` reflects whether a refresh token exists.
- Screens redirect to `/auth` when not logged in.
- `AuthViewModel.logout()` clears tokens and navigates back to auth.

---

## 5. MVVM data flow (example: items)

```
HomeTab (View)
      │ listens to
      ▼
ItemViewModel (ChangeNotifier) ── isLoading / error / items
      │ calls
      ▼
ItemRepository (interface) ───────▶ ItemRepositoryImpl
      │                                  │
      ▼                                  ▼
ApiClient ◄──────────────────────── Express /items
      │
      ▼
HTTP response (JSON) → parsed to List<ItemModel>
```

---

## 6. Error handling across the boundary

| Layer | Mechanism |
|-------|-----------|
| Express backend | Consistent JSON `{ success:false, message }` |
| Flutter `ApiClient` | Maps status codes → typed `AppException` subclasses |
| Flutter Repository | Lets exceptions propagate to the ViewModel |
| Flutter ViewModel | Catches exceptions, calls `setError(message)` via `runWithLoading` |
| Flutter View | Reads `viewModel.error` and shows it (retry button / error state) |

Example errors the user sees: "Invalid email or password", "Item not found",
"Network error: ...".

---

## 7. Chat (REST API)

```
ConversationListPage / ChatPage (View)
      │ observes / calls
      ▼
ConversationViewModel / ChatViewModel (ChangeNotifier)
      │ calls
      ▼
ChatService ──▶ ApiClient ──▶ Express /api/chats
```

- Conversations are fetched from `/api/chats`; message history and sends use
  `/api/chats/:id/messages`, and incoming messages are marked read with
  `PATCH /api/chats/:id/read`.
- The app polls for conversation and message updates because chat is not using
  a WebSocket connection.
- Start chats from a loan during handover/active-loan stages, or use
  **Contact admin** from the profile.

---

## 8. Running frontend with backend

```bash
# Terminal 1 — backend (Node.js/Express)
cd path/to/backend
npm install
npm run dev      # http://localhost:5000

# Terminal 2 — flutter
cd Borrow-Circle-Frontend
flutter pub get
flutter run      # ensure baseUrl matches the backend port
```

Then register or log in (demo mode works without a backend), browse items,
send requests, and open a conversation from a loan or the profile's Contact
admin entry.

---

## 9. File map (integration-relevant)

| File | Role |
|------|------|
| `lib/main.dart` | Dependency-injection composition root |
| `lib/app.dart` | MaterialApp + theme + routes |
| `lib/core/constants/app_constants.dart` | API base URL + endpoints |
| `lib/core/network/api_client.dart` | HTTP client + Bearer token + error mapping |
| `lib/core/network/app_exception.dart` | Typed data-layer exceptions |
| `lib/data/datasources/local/token_storage.dart` | SharedPreferences token persistence |
| `lib/data/repositories/*_repository_impl.dart` | HTTP API implementations per feature |
| `lib/data/services/chat_service.dart` | REST chat service |
| `lib/presentation/viewmodels/*_viewmodel.dart` | UI state and actions |
| `lib/presentation/screens/*` | Pages (observe ViewModels only) |
| `lib/presentation/routes/app_routes.dart` | Named route table |
