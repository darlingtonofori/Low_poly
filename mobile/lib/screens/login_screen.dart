import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pressable_slab.dart';

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
        SnackBar(
          backgroundColor: LowpolyColors.surface,
          content: Text(
            'Google Sign-In not configured yet — use Guest mode below to test.',
            style: LowpolyTextStyles.body(size: 14),
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
      body: LowpolyBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: LowpolyColors.primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: LowpolyColors.primary.withOpacity(0.4), blurRadius: 24, spreadRadius: 2),
                      ],
                    ),
                    child: const Icon(Icons.grid_view_rounded, size: 48, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Lowpoly', textAlign: TextAlign.center, style: LowpolyTextStyles.display(size: 40)),
                const SizedBox(height: 4),
                Text(
                  'Simple games. Live 1v1. No fluff.',
                  textAlign: TextAlign.center,
                  style: LowpolyTextStyles.body(size: 14, color: LowpolyColors.textMuted),
                ),
                const SizedBox(height: 48),
                PressableSlab(
                  faceColor: LowpolyColors.primary,
                  shadowColor: LowpolyColors.primaryShadow,
                  onTap: _busy ? null : _handleGoogle,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        _busy ? 'Signing in...' : 'Continue with Google',
                        style: LowpolyTextStyles.body(size: 16, weight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.15))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('testing without Firebase?', style: LowpolyTextStyles.body(size: 11, color: LowpolyColors.textMuted)),
                    ),
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.15))),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _guestController,
                  style: LowpolyTextStyles.body(size: 15),
                  decoration: const InputDecoration(labelText: 'Guest name'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _handleGuest,
                  child: const Text('Continue as Guest'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
