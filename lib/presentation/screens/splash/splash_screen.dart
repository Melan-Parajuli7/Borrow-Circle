import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../widgets/app_widgets.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../welcome/welcome_screen.dart';
import '../home/home_screen.dart';

/// Initial splash screen that checks for an existing session.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final authViewModel = context.read<AuthViewModel>();

    // Wait for the login check AND at least 1.5 seconds so the logo is visible
    await Future.wait([
      authViewModel.tryAutoLogin(),
      Future.delayed(const Duration(milliseconds: 1500)),
    ]);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => authViewModel.isLoggedIn ? const HomeScreen() : const WelcomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(size: 130),
            SizedBox(height: 60),
            SizedBox(
              height: 44,
              width: 44,
              child: CircularProgressIndicator(strokeWidth: 4, color: AppColors.primary),
            ),
            SizedBox(height: 40),
            Text(
              'Loading Your Circle .....',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark),
            ),
            SizedBox(height: 8),
            Text('Just a moment, We are getting ready', style: TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }
}