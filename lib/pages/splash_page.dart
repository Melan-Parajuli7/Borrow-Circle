import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:borrowcircle/controller/auth_controller.dart';
import 'package:borrowcircle/core/colors.dart';
import 'package:borrowcircle/core/widgets.dart';
import 'package:borrowcircle/pages/home.dart';
import 'package:borrowcircle/pages/welcome.dart';

/// "Loading Your Circle" screen. Checks if the user is already logged in.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final auth = context.read<AuthController>();

    // wait for the login check AND at least 1.5 seconds so the logo is visible
    await Future.wait([
      auth.tryAutoLogin(),
      Future.delayed(const Duration(milliseconds: 1500)),
    ]);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => auth.isLoggedIn ? const HomePage() : const WelcomePage(),
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
