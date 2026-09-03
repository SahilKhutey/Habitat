// Tactical Register Screen
import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _handleRegister() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      AppFeedback.showToast(context, message: 'All fields are required', isError: true);
      return;
    }

    if (password.length < 8) {
      AppFeedback.showToast(context, message: 'Password must be at least 8 characters', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isLoading = false);
        AppFeedback.showToast(context, message: 'Welcome to Discipline! +100 XP Recruiter Bonus Awarded.');
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('CREATE ACCOUNT'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('RECRUIT REGISTRATION', style: AppTypography.labelLarge),
              const SizedBox(height: AppSpacing.xs),
              const Text('Join the Discipline Order', style: AppTypography.displayMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Instant +100 XP starting bonus deposited into your immutable audit ledger upon registration.',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              AppTextField(
                label: 'Display Name',
                hintText: 'Display Name',
                controller: _nameController,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Email Address',
                hintText: 'user@example.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Password (Min. 8 characters)',
                hintText: '••••••••••••',
                controller: _passwordController,
                isPassword: true,
              ),
              const SizedBox(height: AppSpacing.xxl),

              AppButton.primary(
                label: 'CREATE ACCOUNT & CLAIM +100 XP',
                icon: Icons.shield,
                isLoading: _isLoading,
                onPressed: _handleRegister,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
