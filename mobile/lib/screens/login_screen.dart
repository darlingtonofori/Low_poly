import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoggedIn;
  const LoginScreen({super.key, required this.onLoggedIn});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _busy = false;
  final _guestController = TextEditingController();

  Future<void> _handleGoogle() async {
    setState(() => _busy = true);
    final ok = await AuthService.instance.signInWithGoogle();
    setState(() => _busy = false);
    if (ok) {
      widget.onLoggedIn();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Google Sign-In not configured yet — use Guest mode below to test.',
          ),
        ),
      );
    }
  }

  Future<void> _handleGuest() async {
    final ok = await AuthService.instance.signInAsGuest(_guestController.text);
    if (ok) widget.onLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.grid_view_rounded, size: 72, color: Color(0xFF6C63FF)),
              const SizedBox(height: 16),
              const Text(
                'Lowpoly',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Simple games. Live 1v1. No fluff.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: _busy ? null : _handleGoogle,
                icon: const Icon(Icons.login),
                label: Text(_busy ? 'Signing in...' : 'Continue with Google'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Testing without Firebase set up yet?', style: TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                controller: _guestController,
                decoration: const InputDecoration(
                  labelText: 'Guest name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _handleGuest,
                child: const Text('Continue as Guest'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
