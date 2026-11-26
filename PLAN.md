# BorrowCircle Frontend — Refactor & Chat Plan

> Historical note: the original Firestore chat plan below has been superseded.
> The current chat frontend uses the authenticated REST API; see `INTEGRATION.md`.

Target: `Borrow-Circle-Frontend` (`lib/`).
Reference structure/style: `TODO-APP-PCPS/flutter_app` (MVVM, Provider, doc-comment style).
Reference chat feature: `madpcpsgit2026` (Firestore conversations + messages).

## Rules
- Do not change Gradle, Kotlin, or Dart versions. The app runs now.
- Do not change existing UI, features, or the Express backend API.
- If a Firebase package needs a version change, use an older compatible version.
- Work in small steps: `flutter analyze` and `flutter run` after each step.
- One commit per step, using the repo's commit style (see `git log --oneline`).
- Chat rule: Page → ViewModel → Service. Pages never call Firestore directly.

## Layout (matches TODO-APP-PCPS/flutter_app/lib)
```
lib/
├── main.dart              # DI (MultiProvider) + runApp
├── app.dart               # MaterialApp + routes
├── core/
│   ├── constants/         # app_constants, colors, app_static
│   └── network/           # api_client, app_exception
├── data/
│   ├── models/            # conversation_model, message_model, ...
│   ├── repositories/      # repository implementations (HTTP API)
│   └── services/          # chat_service (Firestore only)
└── presentation/
    ├── routes/            # app_routes
    ├── viewmodels/        # base_viewmodel + feature viewmodels
    ├── views/screens/     # pages (home, profile, chat/conversation pages...)
    ├── widgets/           # reusable UI (calendar_widget, message_bubble...)
    ├── theme/             # app_theme
    └── utils/             # validators, format, notification_generator
```

## Commits (one per step)
1. `refactor: restructure folders to MVVM` — verify `lib/` matches the reference layout (already in place from the last restructure; imports/comments aligned).
2. `refactor: move calendar to widgets` — `CalendarScreen` body → `presentation/widgets/calendar_widget.dart`; screen becomes a thin wrapper.
3. `docs: add README, API_DOCS, INTEGRATION` — same format/tone as `TODO-APP-PCPS`.
4. `chore: add firebase setup` — `firebase_core` + `cloud_firestore` (versions compatible with Dart 3.13.4), `lib/firebase_options.dart`, initialise Firebase in `main.dart`.
5. `feat: add chat models and service` — `data/models/conversation_model.dart`, `data/models/message_model.dart`, `data/services/chat_service.dart` (Firestore only).
6. `feat: add chat viewmodels` — `presentation/viewmodels/conversation_viewmodel.dart`, `presentation/viewmodels/chat_viewmodel.dart`.
7. `feat: add conversation and chat pages` — `presentation/screens/chat/conversation_list_page.dart`, `chat_page.dart` + `widgets/conversation_tile.dart`, `message_bubble.dart`, `chat_input_field.dart`.
8. `feat: route dashboard to conversation page` — routes `/conversations` and `/chat`; dashboard button/icon → conversation page.

## Firestore data model
```
conversations/{conversationId}
  participantIds: List<String>
  participantNames: Map<String, String>
  lastMessage: String
  lastMessageAt: Timestamp
  itemId: String?

conversations/{conversationId}/messages/{messageId}
  senderId: String
  text: String
  sentAt: Timestamp
  isRead: bool
```

## Notes
- The existing HTTP-backed chat (Express API) is replaced by the Firestore-based chat so the file names and routes (`/conversations`, `/chat`) from the plan can be used without collisions. The Express backend API itself is unchanged.
- `google-services.json` already exists in `android/app/` (project `borrowcircle-84813`). Flutter-side config lives in `lib/firebase_options.dart`; no Gradle/Kotlin/Dart version changes.
- Devices available for testing: Windows desktop, Chrome, Edge (no Android emulator), so `flutter run` targets Windows/web.
