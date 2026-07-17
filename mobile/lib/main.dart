import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const LowpolyApp());
}

class LowpolyApp extends StatelessWidget {
  const LowpolyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lowpoly',
      debugShowCheckedModeBanner: false,
      theme: buildLowpolyTheme(),
      home: const AuthGate(),
    );
  }
}

/// Decides whether to show Login or Home based on stored session.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final loggedIn = await AuthService.instance.isLoggedIn();
    setState(() {
      _loggedIn = loggedIn;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: LowpolyBackground(
          child: Center(child: CircularProgressIndicator(color: LowpolyColors.primary)),
        ),
      );
    }
    return _loggedIn
        ? const HomeScreen()
        : LoginScreen(onLoggedIn: () => setState(() => _loggedIn = true));
  }
}
