# BorrowCircle

**BorrowCircle** is a community-driven Flutter application for sharing and borrowing items within trusted circles (e.g., campus, student communities, neighborhood groups). By enabling peer-to-peer item sharing, BorrowCircle promotes a sustainable circular economy, reduces unnecessary purchases, and connects community members.

---

## 🌟 Key Features

- **🔐 Authentication & User Verification**
  - Secure Sign Up & Login with JWT session persistence using `SharedPreferences`.
  - Restricted registration by recognized email domains (e.g., campus/university domains).

- **👥 Circles & Groups**
  - Join or select community borrowing circles to view items listed within your trusted network.

- **📦 Item Listing & Catalog**
  - List items with photos, categories, condition ratings (`new`, `like_new`, `good`, `fair`, `poor`), and availability.
  - Browse available items with filtering by category and search capabilities.
  - Manage "My Listings" to update item details or availability.

- **📝 Borrowing Requests**
  - Submit request specifying desired borrow dates (up to 30 days).
  - Item owners can review, accept, or decline pending requests.

- **🤝 Handover & Return Verification**
  - Secure item handover verification using QR code generation (`qr_flutter`) and confirmation codes.
  - Smooth item return workflow tracking item condition and return status.

- **🔄 Active Loan & History Tracking**
  - Track active loans, pending handovers, returns, and past borrowing history in real-time.

- **⭐ Reviews & Ratings**
  - Leave ratings and reviews following completed loans to build trust within the community circle.

---

## 🛠️ Architecture & Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (Dart SDK ^3.13.4)
- **State Management**: [Provider](https://pub.dev/packages/provider) (`MultiProvider`, `ChangeNotifierProvider`)
- **Networking**: REST API via `http` client supporting multipart photo uploads.
- **Local Storage**: `shared_preferences` for secure auth token and user session persistence.
- **UI & Components**: Custom Material 3 styling (`AppTheme`), `image_picker` for photo selection, `qr_flutter` for QR code rendering, and `intl` for date formatting.

---

## 📁 Project Structure

```text
lib/
├── main.dart                  # App entry point & MultiProvider initialization
├── controller/                # Provider State Controllers
│   ├── apicall.dart           # API state helper
│   ├── auth_controller.dart   # User state & authentication flow
│   ├── group_controller.dart  # Circle/Group selection state
│   ├── item_controller.dart   # Item catalog & listing management
│   ├── loan_controller.dart   # Active loans & handover state
│   ├── request_controller.dart# Borrow request workflows
│   └── review_controller.dart # Ratings & reviews state
├── core/                      # Application constants, theme, & shared widgets
│   ├── colors.dart            # Palette & color definitions
│   ├── format.dart            # Date & currency formatting utilities
│   ├── static.dart            # API host endpoints, domain rules, categories
│   ├── theme.dart             # Custom Material 3 theme configuration
│   ├── validators.dart        # Form input validators
│   └── widgets.dart           # Custom buttons, input fields, cards, & loaders
├── model/                     # Data models
│   ├── group_model.dart
│   ├── item_model.dart
│   ├── loan_model.dart
│   ├── request_model.dart
│   ├── review_model.dart
│   ├── user_model.dart
│   └── paged.dart             # Pagination wrapper
├── pages/                     # App UI Screens
│   ├── splash_page.dart       # Initial splash & auto-login check
│   ├── welcome.dart           # Onboarding screen
│   ├── auth.dart              # Login & Register views
│   ├── home.dart              # Main tab navigation & home dashboard
│   ├── select_group.dart      # Circle / Group selection view
│   ├── all_items.dart         # Item catalog with search & filters
│   ├── item_details.dart      # Item detail view & borrow action
│   ├── add_item.dart          # Create/Edit listing screen
│   ├── my_listings.dart       # User listed items management
│   ├── make_request.dart      # Request borrowing form screen
│   ├── requests.dart          # Inbound & Outbound requests list
│   ├── handover.dart          # QR Code & code handover verification
│   ├── loans.dart             # Active loans & history
│   ├── return_item.dart       # Item return confirmation screen
│   ├── review.dart            # Post-loan rating & review screen
│   └── profile.dart           # User profile management & settings
└── services/                  # Backend REST API Communication
    ├── api_service.dart       # Base HTTP client with JWT interceptor
    ├── auth_service.dart
    ├── group_service.dart
    ├── item_service.dart
    ├── loan_service.dart
    ├── request_service.dart
    ├── review_service.dart
    └── token_storage.dart     # SharedPreferences token persistence
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.13.4` or compatible)
- [Dart SDK](https://dart.dev/get-started)
- Android Studio or VS Code with Flutter extension.
- Running **BorrowCircle Backend API** server (Node.js/Express).

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/borrowcircle.git
   cd borrowcircle
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure API Endpoint:**
   - By default, the app targets `http://10.0.2.2:5000/api` on Android Emulators or `http://localhost:5000/api` on desktop/web.
   - You can supply a custom backend host when launching the app:
     ```bash
     flutter run --dart-define=API_HOST=http://<YOUR_LOCAL_IP>:5000
     ```

4. **Run the app:**
   ```bash
   flutter run
   ```

---

## 📄 License

This project is open-source and available under the [MIT License](LICENSE).
