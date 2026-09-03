// Authentication Screen (Sign In & Sign Up with Tactical UI)
import 'package:flutter/material.dart';
import '../../../core/theme/habitat_theme.dart';
import '../domain/auth_models.dart';

import '../../../../database/local_database.dart';

class AuthScreen extends StatefulWidget {
  final Function(AuthSession session)? onAuthenticated;

  const AuthScreen({super.key, this.onAuthenticated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignUp = false;
  bool _isLoading = false;
  String? _errorMessage;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  void _handleSubmit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@') || password.length < 6) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please enter a valid email and 6+ character password.';
        });
      }
      return;
    }

    final db = LocalDatabase.instance;
    final profileName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : email.split('@').first;
    final localUser = db.getOrCreateProfile(name: profileName);
    final streak = db.getStreak();
    final totalXp = db.getTotalXP();

    final session = AuthSession(
      user: UserProfile(
        id: localUser.id,
        email: email,
        displayName: localUser.displayName,
        disciplineScore: 100,
        autonomyLevel: 1,
        currentStreak: streak.currentStreak,
        longestStreak: streak.longestStreak,
        totalXp: totalXp,
      ),
      token: 'habitat_session_${localUser.id}_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (mounted) {
      setState(() => _isLoading = false);
      widget.onAuthenticated?.call(session);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HabitatTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo & Header
                const Center(
                  child: Icon(Icons.shield, size: 64, color: HabitatTheme.amberFocus),
                ),
                const SizedBox(height: 16),
                const Text(
                  'HABITAT',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: HabitatTheme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'DISCIPLINE & BEHAVIOR ENGINE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: HabitatTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 36),

                // Error Message
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: HabitatTheme.crimsonAlert.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: HabitatTheme.crimsonAlert),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: HabitatTheme.crimsonAlert, fontSize: 13),
                    ),
                  ),

                // Form Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: HabitatTheme.surfacePrimary,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: HabitatTheme.surfaceBorder),
                  ),
                  child: Column(
                    children: [
                      if (_isSignUp) ...[
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Display Name',
                            prefixIcon: Icon(Icons.person_outline, color: HabitatTheme.textSecondary),
                            border: UnderlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email_outlined, color: HabitatTheme.textSecondary),
                          border: UnderlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline, color: HabitatTheme.textSecondary),
                          border: UnderlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HabitatTheme.amberFocus,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _handleSubmit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                          )
                        : Text(
                            _isSignUp ? 'CREATE DISCIPLINE ACCOUNT' : 'ENTER HABITAT',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Switch Sign In / Sign Up
                TextButton(
                  onPressed: () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(
                    _isSignUp ? 'Already have an account? Sign In' : "Don't have an account? Create One",
                    style: const TextStyle(color: HabitatTheme.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
