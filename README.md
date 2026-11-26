# BorrowCircle — Flutter (MVVM)

**BorrowCircle** is a community-driven Flutter application for sharing and borrowing items within trusted circles (e.g., campus, student communities, neighborhood groups). By enabling peer-to-peer item sharing, BorrowCircle promotes a sustainable circular economy, reduces unnecessary purchases, and connects community members.

The frontend follows **MVVM architecture** (View ←→ ViewModel ←→ Repository ←→ API client) with **Provider** for state management, matching the structure and style of the reference `TODO-APP-PCPS/flutter_app` project.

```
borrowcircle/
├── android/             # Android project
├── lib/
│   ├── main.dart        # Entry point: DI (MultiProvider) + runApp
│   ├── app.dart         # MaterialApp, theme, named routes
│   ├── core/
│   │   ├── constants/   # app_constants, colors, app_static
│   │   └── network/     # api_client, app_exception
│   ├── data/
│   │   ├── models/      # item, loan, request, review, user, chat models...
│   │   ├── repositories/# HTTP API repository implementations
│   │   └── services/    # chat_service (REST API)
│   ├── presentation/
│   │   ├── routes/      # app_routes
│   │   ├── viewmodels/  # base_viewmodel + feature viewmodels
│   │   ├── screens/     # pages (home, profile, chat, calendar, ...)
│   │   ├── widgets/     # reusable UI (calendar_widget, message_bubble, ...)
│   │   ├── theme/       # app_theme
│   │   └── utils/       # validators, format, notification_generator
├── test/
├── pubspec.yaml
├── README.md            # this file
├── API_DOCS.md          # REST API reference (Node.js/Express backend)
└── INTEGRATION.md       # How the Flutter app connects to the backend
```

---

## Features

- **Authentication**: Register, login, JWT session persistence via `SharedPreferences`; demo mode when the backend is unavailable.
- **Items**: Browse, search, filter, list items with photos; manage "My Listings".
- **Requests**: Send borrow requests; owners accept or decline.
- **Loans**: Track active borrowing/lending, handover with QR codes, returns.
- **Reviews**: Rate and review completed loans.
- **Calendar**: Widget-based loan calendar (start/due dates) with "add to device calendar".
- **Notifications**: Local notifications for requests, loans, and chat messages.
- **Chat**: Loan coordination and admin support conversations through the REST API.
- **Appearance**: Light/dark/system theme persisted per user.

---

## Architecture (MVVM)

```
View (Screen)  →  ViewModel (ChangeNotifier)  →  Repository / Service  →  Data source
```

- `presentation/viewmodels/` — hold UI state (`isLoading`, `error`) and expose actions.
- `presentation/screens/` — pages; they observe ViewModels via `Provider`/`Consumer` and never call the network directly.
- `data/repositories/` — HTTP API implementations backed by `core/network/api_client.dart`.
- `data/services/chat_service.dart` — REST service for conversations and messages.
- State management: **Provider** (`ChangeNotifierProvider`, `MultiProvider`).

## Tech Stack

| Layer | Tech |
|-------|------|
| Framework | Flutter (Dart SDK ^3.13.4) |
| State management | Provider |
| Networking | `http` (REST API, multipart uploads) |
| Chat | REST API via `http` |
| Local storage | `shared_preferences` |
| Calendar | `table_calendar`, `add_2_calendar` |
| Images/QR | `image_picker`, `qr_flutter` |
| Dates | `intl` |

## Quick Start

```bash
cd Borrow-Circle-Frontend
flutter pub get
flutter run               # Windows desktop, Chrome, Edge, or attached Android device
```

The app targets `http://10.0.2.2:5000` by default (Android emulator). Configure the backend host in:

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

## Chat

Chats use the authenticated backend endpoints documented in `API_DOCS.md`.
Users can start a loan conversation from the handover or active-loan screen and
contact admin support from their profile. The app polls for new messages; it
does not use a WebSocket connection.

## Scripts

- `flutter run` — run on connected device/emulator
- `flutter build apk --debug` — build debug APK
- `flutter analyze` — lint
- `flutter test` — run tests

## License

MIT
