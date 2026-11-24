import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../utils/validators.dart';
import '../../widgets/app_widgets.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/fingerprint_viewmodel.dart';
import '../home/home_screen.dart';

/// Login + Register screen (the "Log in | Sign up" tabs from the Figma).
class AuthScreen extends StatefulWidget {
  final bool startOnSignUp;
  const AuthScreen({super.key, this.startOnSignUp = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FingerprintViewModel>().load();
    });
  }

  @override
  void dispose() {
    for (final c in [
      _loginEmail,
      _loginPassword,
      _name,
      _email,
      _password,
      _confirm,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  Future<void> _login() async {
    if (!_loginKey.currentState!.validate()) return;
    final authViewModel = context.read<AuthViewModel>();
    final ok = await authViewModel.login(_loginEmail.text, _loginPassword.text);
    if (!mounted) return;
    ok
        ? _goHome()
        : showSnack(context, authViewModel.error ?? 'Login failed', isError: true);
  }

  Future<void> _fingerprintLogin() async {
    final fingerprintViewModel = context.read<FingerprintViewModel>();
    if (!fingerprintViewModel.enabled) {
      showSnack(context, 'Enable fingerprint login in Account settings first.');
      return;
    }

    final authenticated = await fingerprintViewModel.authenticate();
    if (!mounted) return;
    if (!authenticated) {
      showSnack(
        context,
        fingerprintViewModel.error ?? 'Fingerprint authentication failed',
        isError: true,
      );
      return;
    }

    final authViewModel = context.read<AuthViewModel>();
    await authViewModel.tryAutoLogin();
    if (!mounted) return;
    authViewModel.isLoggedIn
        ? _goHome()
        : showSnack(
            context,
            'No saved login session. Log in once with your password.',
            isError: true,
          );
  }

  Future<void> _signup() async {
    if (!_signupKey.currentState!.validate()) return;
    final authViewModel = context.read<AuthViewModel>();
    final ok = await authViewModel.register(_name.text, _email.text, _password.text);
    if (!mounted) return;
    ok
        ? _goHome()
        : showSnack(
            context,
            authViewModel.error ?? 'Registration failed',
            isError: true,
          );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final loading = authViewModel.isLoading;
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
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isLogin
                          ? 'Log in to borrow, lend and connect with your university community.'
                          : 'Create an account to borrow, lend and connect with your University Community',
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        color: AppColors.textGrey,
                      ),
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
                    const InfoBanner(
                      text: 'Your university email keeps BorrowCircle safe and campus-only.',
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isLogin ? 'New here?' : 'Already have an account?',
                            style: const TextStyle(color: AppColors.textGrey),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _tab = isLogin ? 1 : 0),
                            child: Text(isLogin ? 'Create an account' : 'Log in'),
                          ),
                        ],
                      ),
                    ),
                    const Center(
                      child: Text(
                        'By continuing, you agree to our Terms of Service\nand Privacy Policy.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 13,
                        ),
                      ),
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
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
              ),
              child: const Text('Forgot password?'),
            ),
          ),
          const SizedBox(height: 4),
          PrimaryButton(
            text: 'Log in',
            icon: Icons.arrow_forward,
            isLoading: loading,
            onPressed: _login,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _fingerprintLogin,
            icon: const Icon(Icons.fingerprint),
            label: const Text('Use fingerprint'),
          ),
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
          PrimaryButton(
            text: 'Create Account',
            icon: Icons.arrow_forward,
            isLoading: loading,
            onPressed: _signup,
          ),
        ],
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset unavailable'),
        content: const Text(
          'Password reset requires backend support. No reset email has been sent.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Forgot password'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lock_reset_outlined,
                        size: 72,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Reset your password',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enter your university email to check password recovery options.',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppTextField(
                        controller: _email,
                        label: 'University email',
                        hint: 'you@patancollege.edu.np',
                        suffixIcon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        text: 'Continue',
                        icon: Icons.arrow_forward,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}