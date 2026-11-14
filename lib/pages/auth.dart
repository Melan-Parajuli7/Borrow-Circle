import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:borrowcircle/controller/auth_controller.dart';
import 'package:borrowcircle/core/colors.dart';
import 'package:borrowcircle/core/validators.dart';
import 'package:borrowcircle/core/widgets.dart';
import 'package:borrowcircle/pages/home.dart';

/// Login + Register on one screen (the "Log in | Sign up" tabs from the Figma).
class AuthPage extends StatefulWidget {
  final bool startOnSignUp;
  const AuthPage({super.key, this.startOnSignUp = false});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late int _tab = widget.startOnSignUp ? 1 : 0; // 0 = log in, 1 = sign up

  final _loginKey = GlobalKey<FormState>();
  final _signupKey = GlobalKey<FormState>();

  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    for (final c in [_loginEmail, _loginPassword, _name, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  Future<void> _login() async {
    if (!_loginKey.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    final ok = await auth.login(_loginEmail.text, _loginPassword.text);
    if (!mounted) return;
    ok ? _goHome() : showSnack(context, auth.error ?? 'Login failed', isError: true);
  }

  Future<void> _signup() async {
    if (!_signupKey.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    final ok = await auth.register(_name.text, _email.text, _password.text);
    if (!mounted) return;
    ok ? _goHome() : showSnack(context, auth.error ?? 'Registration failed', isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthController>().isLoading;
    final isLogin = _tab == 0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Your campus circle'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppLogo(size: 60),
                    const SizedBox(height: 14),
                    Text(
                      isLogin ? 'Good to see you.' : 'Join your Campus circle.',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isLogin
                          ? 'Log in to borrow, lend and connect with your university community.'
                          : 'Create an account to borrow, lend and connect with your University Community',
                      style: const TextStyle(fontSize: 16, height: 1.4, color: AppColors.textGrey),
                    ),
                    const SizedBox(height: 22),
                    SegmentedTabs(
                      labels: const ['Log in', 'Sign up'],
                      selected: _tab,
                      onChanged: (i) => setState(() => _tab = i),
                    ),
                    const SizedBox(height: 22),
                    isLogin ? _loginForm(loading) : _signupForm(loading),
                    const SizedBox(height: 18),
                    const InfoBanner(text: 'Your university email keeps BorrowCircle safe and campus-only.'),
                    const SizedBox(height: 18),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(isLogin ? 'New here?' : 'Already have an account?',
                              style: const TextStyle(color: AppColors.textGrey)),
                          TextButton(
                            onPressed: () => setState(() => _tab = isLogin ? 1 : 0),
                            child: Text(isLogin ? 'Create an account' : 'Log in'),
                          ),
                        ],
                      ),
                    ),
                    const Center(
                      child: Text('By continuing, you agree to our Terms of Service\nand Privacy Policy.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loginForm(bool loading) {
    return Form(
      key: _loginKey,
      child: Column(
        children: [
          AppTextField(
            controller: _loginEmail,
            label: 'University email',
            hint: 'you@study.beds.ac.uk',
            suffixIcon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _loginPassword,
            label: 'Password',
            hint: 'Your password',
            isPassword: true,
            validator: Validators.password,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => showSnack(context, 'Password reset is not available yet.'),
              child: const Text('Forgot password?'),
            ),
          ),
          const SizedBox(height: 4),
          PrimaryButton(text: 'Log in', icon: Icons.arrow_forward, isLoading: loading, onPressed: _login),
        ],
      ),
    );
  }

  Widget _signupForm(bool loading) {
    return Form(
      key: _signupKey,
      child: Column(
        children: [
          AppTextField(
            controller: _name,
            label: 'Full Name',
            hint: 'Your full name',
            validator: Validators.fullName,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _email,
            label: 'University Email',
            hint: 'you@study.beds.ac.uk',
            suffixIcon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _password,
            label: 'Password',
            hint: 'Create a password (min 8 characters)',
            isPassword: true,
            validator: Validators.password,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _confirm,
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            isPassword: true,
            validator: Validators.confirmPassword(() => _password.text),
          ),
          const SizedBox(height: 24),
          PrimaryButton(text: 'Create Account', icon: Icons.arrow_forward, isLoading: loading, onPressed: _signup),
        ],
      ),
    );
  }
}
