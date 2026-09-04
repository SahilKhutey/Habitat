// Tactical Login Screen
import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      AppFeedback.showToast(context,
          message: 'Please enter email and password', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.huge),
              // Header
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.amberFocus,
                  borderRadius: AppRadii.radiusMedium,
                ),
                alignment: Alignment.center,
                child:
                    const Icon(Icons.lock_clock, color: Colors.black, size: 28),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text('DISCIPLINE', style: AppTypography.displayLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Enter credentials to access your daily mission protocol.',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Form
              AppTextField(
                label: 'Email Address',
                hintText: 'alex.mercer@discipline.app',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Password',
                hintText: '••••••••••••',
                controller: _passwordController,
                isPassword: true,
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Login Button
              AppButton.primary(
                label: 'SIGN IN TO DISCIPLINE',
                icon: Icons.login,
                isLoading: _isLoading,
                onPressed: _handleLogin,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Register CTA
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pushNamed('/register'),
                  child: const Text(
                    "DON'T HAVE AN ACCOUNT? REGISTER",
                    style: TextStyle(
                        color: AppColors.amberFocus,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
