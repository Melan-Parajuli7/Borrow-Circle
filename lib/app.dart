import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/colors.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/routes/app_routes.dart';
import 'presentation/viewmodels/account_viewmodel.dart';

/// Root [StatelessWidget] of the BorrowCircle app.
///
/// Configures [MaterialApp] with the app theme, the initial route, and the
/// named route table defined in [AppRoutes]. The active theme mode is driven
/// by [AccountViewModel] so the user's appearance preference is applied
/// app-wide.
class BorrowCircleApp extends StatelessWidget {
  /// Creates a [BorrowCircleApp] with an optional [key].
  const BorrowCircleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountViewModel>(
      builder: (context, account, _) => MaterialApp(
        title: 'Borrow Circle',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.dark,
          ),
        ),
        themeMode: account.themeMode == 'light'
            ? ThemeMode.light
            : account.themeMode == 'dark'
                ? ThemeMode.dark
                : ThemeMode.system,
        // The splash screen performs the session check and redirects to either
        // Home or Welcome accordingly.
        initialRoute: AppRoutes.splash,
        routes: AppRoutes.routes,
        // Fallback for any route not declared in [AppRoutes.routes].
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Page not found')),
            ),
          );
        },
      ),
    );
  }
}
