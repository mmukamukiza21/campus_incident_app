import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: auth.logout),
        ],
      ),
      body: Center(
        child: Text(
          'Hello ${auth.profile?.name ?? ''}\nRole: ${auth.profile?.role ?? '...'}',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}