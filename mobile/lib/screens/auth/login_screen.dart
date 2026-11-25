// lib/screens/auth/login_screen.dart
// Two login views on one screen:
//  - Staff Login (default): Teachers and the Principal / Vice Principal
//  - Admin Login: opened with "Login as Admin" (red Admin badge + "Back to Staff Login")
// The app tells the API which view was used (portal = 'staff' / 'admin'); the API refuses
// an Admin account on Staff Login and a Teacher / VP account on Admin Login (403),
// so nobody is logged in through the wrong door.

import 'package:flutter/material.dart';

import '../../services/current_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/async_views.dart';
import '../home_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false; // shows a spinner on the button
  bool _hidePassword = true;
  bool _isAdminView = false; // false = Staff Login, true = Admin Login

  @override
  void dispose() {
    _loginIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchView(bool admin) {
    setState(() {
      _isAdminView = admin;
      _errorMessage = '';
      _passwordController.clear();
    });
  }

  Future<void> _handleLogin() async {
    final loginId = _loginIdController.text.trim();
    final password = _passwordController.text;

    if (loginId.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields.');
      return;
    }

    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    try {
      final user = await dataService.login(loginId, password,
          portal: _isAdminView ? 'admin' : 'staff');
      if (!mounted) return;
      goToHome(context, user); // role-based routing
    } catch (e) {
      setState(() => _errorMessage = errorText(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.support_agent, size: 40),
        title: const Text('Forgot your password?'),
        content: const Text(
          'Passwords can only be reset by the school Admin.\n\n'
          'Please contact the Admin. They will reset it and send you a '
          'temporary password on Gmail. You will then set a new password '
          'the first time you log in.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = _isAdminView ? AppColors.danger : AppColors.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(_isAdminView ? Icons.admin_panel_settings : Icons.school,
                      size: 90, color: accent),
                  const SizedBox(height: 16),
                  const Text(
                    'School Grading System',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Center(child: _portalBadge(accent)),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _loginIdController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: _isAdminView ? 'Admin Login ID' : 'Login ID',
                      hintText: _isAdminView ? 'e.g. admin@school.com' : 'e.g. sania@school.com',
                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: _hidePassword,
                    onSubmitted: (_) => _handleLogin(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_hidePassword ? Icons.visibility : Icons.visibility_off),
                        tooltip: _hidePassword ? 'Show password' : 'Hide password',
                        onPressed: () => setState(() => _hidePassword = !_hidePassword),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPassword,
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  if (_errorMessage.isNotEmpty) _errorBox(),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(_isAdminView ? Icons.admin_panel_settings : Icons.login),
                    label: Text(_isAdminView ? 'Login as Admin' : 'Login',
                        style: const TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 28),
                  const Row(children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or', style: TextStyle(color: AppColors.muted)),
                    ),
                    Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 16),
                  // Switch between the two login views
                  _isAdminView
                      ? OutlinedButton.icon(
                          onPressed: _isLoading ? null : () => _switchView(false),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back to Staff Login'),
                          style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14)),
                        )
                      : OutlinedButton.icon(
                          onPressed: _isLoading ? null : () => _switchView(true),
                          icon: const Icon(Icons.admin_panel_settings_outlined),
                          label: const Text('Login as Admin'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: AppColors.danger),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // "Teacher / Vice Principal Login" or the red "Admin Login" badge
  Widget _portalBadge(Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_isAdminView ? Icons.shield_outlined : Icons.groups_outlined, size: 18, color: accent),
          const SizedBox(width: 6),
          Text(
            _isAdminView ? 'Admin Login' : 'Teacher / Vice Principal Login',
            style: TextStyle(color: accent, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _errorBox() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage,
              style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
