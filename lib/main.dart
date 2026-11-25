import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:borrowcircle/app.dart';
import 'package:borrowcircle/core/network/api_client.dart';
import 'package:borrowcircle/data/repositories/account_repository_impl.dart';
import 'package:borrowcircle/data/repositories/auth_repository_impl.dart';
import 'package:borrowcircle/data/repositories/calendar_repository_impl.dart';
import 'package:borrowcircle/data/repositories/fingerprint_repository_impl.dart';
import 'package:borrowcircle/data/services/chat_service.dart';
import 'package:borrowcircle/data/repositories/group_repository_impl.dart';
import 'package:borrowcircle/data/repositories/item_repository_impl.dart';
import 'package:borrowcircle/data/repositories/loan_repository_impl.dart';
import 'package:borrowcircle/data/repositories/notification_repository_impl.dart';
import 'package:borrowcircle/data/repositories/password_repository_impl.dart';
import 'package:borrowcircle/data/repositories/request_repository_impl.dart';
import 'package:borrowcircle/data/repositories/review_repository_impl.dart';
import 'package:borrowcircle/presentation/viewmodels/account_viewmodel.dart';
import 'package:borrowcircle/presentation/viewmodels/auth_viewmodel.dart';
import 'package:borrowcircle/presentation/viewmodels/calendar_viewmodel.dart';
import 'package:borrowcircle/presentation/viewmodels/conversation_viewmodel.dart';
import 'package:borrowcircle/presentation/viewmodels/fingerprint_viewmodel.dart';
import 'package:borrowcircle/presentation/viewmodels/group_viewmodel.dart';
import 'package:borrowcircle/presentation/viewmodels/item_viewmodel.dart';
import 'package:borrowcircle/presentation/viewmodels/loan_viewmodel.dart';
import 'package:borrowcircle/presentation/viewmodels/notification_viewmodel.dart';
import 'package:borrowcircle/presentation/viewmodels/password_viewmodel.dart';
import 'package:borrowcircle/presentation/viewmodels/request_viewmodel.dart';
import 'package:borrowcircle/presentation/viewmodels/review_viewmodel.dart';
import 'package:borrowcircle/core/constants/firebase_options.dart';

/// Entry point of the BorrowCircle Flutter application.
///
/// Sets up the dependency injection graph and runs the app with [Provider].
///
/// Steps:
/// 1. Ensures Flutter bindings are initialized (required before using async
///    APIs that touch the framework).
 /// 2. Restores the persisted auth tokens from local storage.
 /// 3. Initialises Firebase (Android only) for the Firestore chat feature.
 /// 4. Creates an [ApiClient] wrapping [http.Client] — the single networking
///    entry point that attaches the session cookies and refreshes tokens.
/// 4. Creates the repository implementations with that [ApiClient] injected.
/// 5. Provides every [ViewModel] via [MultiProvider].
/// 6. Runs [BorrowCircleApp].
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SharedPreferences is used to persist the JWT token across app restarts.
  final prefs = await SharedPreferences.getInstance();

  // Firebase is required by the Firestore chat service. iOS and web are not
  // configured in this build, so initialisation is skipped on those platforms.
  if (DefaultFirebaseOptions.currentPlatform != null) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform!,
    );
  }

  // API client handles HTTP requests and automatically attaches the session
  // cookies. Every repository receives this same instance.
  final apiClient = ApiClient(http.Client(), prefs);

  // Repository implementations backed by the Express API.
  final authRepository = AuthRepositoryImpl(apiClient, prefs);
  final itemRepository = ItemRepositoryImpl(apiClient);
  final requestRepository = RequestRepositoryImpl(apiClient);
  final loanRepository = LoanRepositoryImpl(apiClient);
  final reviewRepository = ReviewRepositoryImpl(apiClient);
  final groupRepository = GroupRepositoryImpl(apiClient);

  runApp(
    Provider(
      create: (_) => ChatService(),
      child: MultiProvider(
        providers: [
        // Authentication & session.
        ChangeNotifierProvider(create: (_) => AuthViewModel(authRepository)),

        // Local-only repositories (preferences, biometrics, notifications).
        ChangeNotifierProvider(create: (_) => AccountViewModel(AccountRepositoryImpl())),
        ChangeNotifierProvider(create: (_) => FingerprintViewModel(FingerprintRepositoryImpl())),
        ChangeNotifierProvider(create: (_) => NotificationViewModel(NotificationRepositoryImpl())),
        ChangeNotifierProvider(create: (_) => PasswordViewModel(PasswordRepositoryImpl())),

        // API-backed repositories.
        ChangeNotifierProvider(create: (_) => ItemViewModel(itemRepository)),
        ChangeNotifierProvider(create: (_) => RequestViewModel(requestRepository)),
        ChangeNotifierProvider(create: (_) => LoanViewModel(loanRepository)),
        ChangeNotifierProvider(create: (_) => ReviewViewModel(reviewRepository)),
        ChangeNotifierProvider(create: (_) => GroupViewModel(groupRepository)),

        // Chat (Firestore).
        ChangeNotifierProvider(
          create: (_) => ConversationViewModel(ChatService()),
        ),

        // Derived state built from the loans above.
        ChangeNotifierProvider(create: (_) => CalendarViewModel(CalendarRepositoryImpl())),
      ],
      child: const BorrowCircleApp(),
      ),
    ),
  );
}