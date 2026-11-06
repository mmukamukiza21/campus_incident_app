import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_unread_outlined, size: 72),
            const SizedBox(height: 16),
            Text(
              'Verify your email',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'We sent a verification link to ${auth.user?.email}. '
              'Open it, then tap the button below.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.read<AuthProvider>().checkVerified(),
              child: const Text("I've verified my email"),
            ),
            TextButton(
              onPressed: () async {
                final ok =
                    await context.read<AuthProvider>().resendVerification();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? 'Verification email sent'
                            : (auth.error ?? 'Could not send'),
                      ),
                    ),
                  );
                }
              },
              child: const Text('Resend email'),
            ),
            TextButton(
              onPressed: () => context.read<AuthProvider>().logout(),
              child: const Text('Back to login'),
            ),
          ],
        ),
      ),
    );
  }
}