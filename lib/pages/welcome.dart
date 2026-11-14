import 'package:flutter/material.dart';

import 'package:borrowcircle/core/colors.dart';
import 'package:borrowcircle/core/widgets.dart';
import 'package:borrowcircle/pages/auth.dart';

/// First screen for people who are not logged in ("Less Building. More Sharing.").
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  void _open(BuildContext context, bool signUp) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AuthPage(startOnSignUp: signUp)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  AppLogo(size: 52),
                  SizedBox(width: 14),
                  Text('BorrowCircle',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                ],
              ),
              const SizedBox(height: 20),

              // Big picture card (replace with a real photo later if you like)
              Container(
                height: 260,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    const Center(child: Icon(Icons.swap_horiz_rounded, color: Colors.white54, size: 130)),
                    Positioned(
                      left: 16,
                      bottom: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.school_outlined, color: AppColors.primary),
                            SizedBox(width: 10),
                            Text('Your campus. Your circle.',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text('Less Building.\nMore Sharing.',
                  style: TextStyle(fontSize: 32, height: 1.25, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              const SizedBox(height: 10),
              const Text('Borrow what you want from students and college groups. Make campus life a little lighter.',
                  style: TextStyle(fontSize: 16, height: 1.4)),
              const SizedBox(height: 14),
              const Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  PillTag(text: 'Student to student', icon: Icons.person_outline),
                  PillTag(text: 'College groups', icon: Icons.groups_outlined),
                ],
              ),
              const SizedBox(height: 28),

              PrimaryButton(text: 'Join your campus', icon: Icons.arrow_forward, onPressed: () => _open(context, true)),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: () => _open(context, false), child: const Text('I already have an account')),
              const SizedBox(height: 16),
              const Center(
                child: Text('Verified students. Shared possibilities.', style: TextStyle(color: AppColors.textGrey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
