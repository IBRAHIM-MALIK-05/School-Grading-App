// lib/screens/admin/credentials_dialog.dart
// Shown to the Admin right after "Create Account" or "Reset Password".
// The temporary password is shown ONLY here, once.
// Sharing: "Copy" (clipboard) or "Open Gmail draft" (pre-filled email that
// the Admin reviews and sends). No SMTP server / email password is needed.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/account.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/async_views.dart';

Future<void> showCredentialsDialog(
  BuildContext context,
  Credentials credentials, {
  required bool isReset,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false, // must press Done
    builder: (_) => _CredentialsDialog(credentials: credentials, isReset: isReset),
  );
}

class _CredentialsDialog extends StatelessWidget {
  final Credentials credentials;
  final bool isReset;
  const _CredentialsDialog({required this.credentials, required this.isReset});

  String get _subject => isReset
      ? 'Your School Grading App password has been reset'
      : 'Your School Grading App account';

  String get _messageText =>
      'Hello ${credentials.fullName},\n\n'
      '${isReset ? 'Your password has been reset by the school Admin.' : 'Your account for the School Grading App has been created.'}\n\n'
      'Login ID: ${credentials.loginId}\n'
      'Temporary password: ${credentials.temporaryPassword}\n\n'
      'You will be asked to set your own password when you log in.\n'
      'Your Login ID cannot be changed.\n\n'
      'Regards,\nSchool Admin';

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _messageText));
    if (context.mounted) showMessage(context, 'Copied to clipboard.');
  }

  Future<void> _openGmail(BuildContext context) async {
    final to = credentials.contactEmail ?? '';
    final Uri uri;
    final isDesktopOrWeb = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;

    if (isDesktopOrWeb) {
      // Gmail "compose" page in the browser
      uri = Uri.https('mail.google.com', '/mail/', {
        'view': 'cm',
        'fs': '1',
        'to': to,
        'su': _subject,
        'body': _messageText,
      });
    } else {
      // Phone: opens the Gmail app (or the default mail app)
      uri = Uri.parse('mailto:$to'
          '?subject=${Uri.encodeComponent(_subject)}'
          '&body=${Uri.encodeComponent(_messageText)}');
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      showMessage(context, 'Could not open Gmail. Please use Copy instead.',
          isError: true);
    }
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Expanded(
            child: SelectableText(value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true, // fits small phone screens
      icon: const Icon(Icons.verified_user, color: AppColors.success, size: 40),
      title: Text(isReset ? 'Password reset' : 'Account created'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('Name', credentials.fullName),
          _row('Login ID', credentials.loginId),
          _row('Temporary password', credentials.temporaryPassword),
          if (credentials.contactEmail != null)
            _row('Send to', credentials.contactEmail!),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.amber.shade50,
            child: const Text(
              'This password is shown only once. Share it now.\n'
              'The user must change it at first login.',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () => _copy(context),
          icon: const Icon(Icons.copy),
          label: const Text('Copy'),
        ),
        TextButton.icon(
          onPressed: () => _openGmail(context),
          icon: const Icon(Icons.mail_outline),
          label: const Text('Open Gmail draft'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
