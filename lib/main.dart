import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:borrowcircle/app.dart';
import 'package:borrowcircle/core/network/api_client.dart';
import 'package:borrowcircle/data/datasources/local/token_storage.dart';
import 'package:borrowcircle/data/repositories/account_repository_impl.dart';
import 'package:borrowcircle/data/repositories/auth_repository_impl.dart';
import 'package:borrowcircle/data/repositories/calendar_repository_impl.dart';
import 'package:borrowcircle/data/repositories/fingerprint_repository_impl.dart';
import 'package:borrowcircle/data/repositories/chat_repository_impl.dart';
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
import 'package:borrowcircle/presentation/viewmodels/chat_viewmodel.dart';
import 'package:borrowcircle/presentation/viewmodels/fingerprint_viewmodel.dart';
import 'package:borrowcircle/presentation/viewmodels/group_viewmodel.dart';
import 'package:borrowcircle/presentation/viewmodels/item_viewmodel.dart';
import 'package:borrowcircle/presentation/viewmodels/loan_viewmodel.dart';
import 'package:borrowcircle/presentation/viewmodels/notification_viewmodel.dart';
import 'package:borrowcircle/presentation/viewmodels/password_viewmodel.dart';
import 'package:borrowcircle/presentation/viewmodels/request_viewmodel.dart';
import 'package:borrowcircle/presentation/viewmodels/review_viewmodel.dart';

/// Entry point of the BorrowCircle Flutter application.
///
/// Sets up the dependency injection graph and runs the app with [Provider].
///
/// Steps:
/// 1. Ensures Flutter bindings are initialized (required before using async
///    APIs that touch the framework).
/// 2. Restores the persisted auth tokens from local storage.
/// 3. Creates an [ApiClient] wrapping [http.Client] — the single networking
///    entry point that attaches the session cookies and refreshes tokens.
/// 4. Creates the repository implementations with that [ApiClient] injected.
/// 5. Provides every [ViewModel] via [MultiProvider].
/// 6. Runs [BorrowCircleApp].
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Tokens are persisted in SharedPreferences and restored before the first
  // request so the splash screen can restore an existing session.
  await TokenStorage.load();

  // API client handles HTTP requests and automatically attaches the session
  // cookies. Every repository receives this same instance.
  final apiClient = ApiClient(http.Client());

  // Repository implementations backed by the Express API.
  final authRepository = AuthRepositoryImpl(apiClient);
  final itemRepository = ItemRepositoryImpl(apiClient);
  final requestRepository = RequestRepositoryImpl(apiClient);
  final loanRepository = LoanRepositoryImpl(apiClient);
  final reviewRepository = ReviewRepositoryImpl(apiClient);
  final groupRepository = GroupRepositoryImpl(apiClient);
  final chatRepository = ChatRepositoryImpl(apiClient);

  runApp(
    MultiProvider(
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
        ChangeNotifierProvider(create: (_) => ChatViewModel(chatRepository)),

        // Derived state built from the loans above.
        ChangeNotifierProvider(create: (_) => CalendarViewModel(CalendarRepositoryImpl())),
      ],
      child: const BorrowCircleApp(),
    ),
  );
}