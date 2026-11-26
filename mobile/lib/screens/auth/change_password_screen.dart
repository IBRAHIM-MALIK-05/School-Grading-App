// lib/screens/auth/change_password_screen.dart
// Two modes:
//  forced = true  -> first login / after Admin reset. No back button,
//                    user MUST set a new password before using the app.
//  forced = false -> opened from the side menu, can go back.

import 'package:flutter/material.dart';

import '../../services/current_service.dart';
import '../../services/notification_center.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/async_views.dart';
import '../home_router.dart';
import 'login_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  final bool forced;
  const ChangePasswordScreen({super.key, required this.forced});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await dataService.changePassword(
          _currentController.text, _newController.text);
      if (!mounted) return;
      showMessage(context, 'Password changed successfully.');
      if (widget.forced) {
        // Now they may enter the app
        goToHome(context, dataService.currentUser!);
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _logout() {
    notificationCenter.stop();
    dataService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = dataService.currentUser;

    return PopScope(
      canPop: !widget.forced, // block the Android back button when forced
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Change Password'),
          automaticallyImplyLeading: !widget.forced,
          actions: [
            if (widget.forced)
              TextButton(
                onPressed: _logout,
                child: const Text('Logout', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.forced)
                      Card(
                        color: Colors.amber.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Welcome ${user?.fullName ?? ''}!\n\n'
                            'You are using a temporary password. '
                            'Please set your own password to continue.',
                          ),
                        ),
                      ),
                    if (user != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('Login ID: ${user.loginId} (cannot be changed)',
                            style: const TextStyle(color: AppColors.muted)),
                      ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _currentController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: widget.forced
                            ? 'Temporary password'
                            : 'Current password',
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New password',
                        prefixIcon: Icon(Icons.lock),
                        helperText:
                            'At least 8 characters, with a letter and a number',
                      ),
                      validator: (v) {
                        if (v == null || v.length < 8) {
                          return 'At least 8 characters';
                        }
                        return null; // other rules are checked by the server
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm new password',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      validator: (v) => v != _newController.text
                          ? 'Passwords do not match'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _isSaving ? null : _save,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save new password'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
