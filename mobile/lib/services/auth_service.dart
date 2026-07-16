import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Handles Google Sign-In and local session state.
///
/// NOTE: To make Google Sign-In actually work you need to:
/// 1. Create a Firebase project (console.firebase.google.com)
/// 2. Add your Android app (package name must match applicationId
///    in mobile/android/app/build.gradle)
/// 3. Download google-services.json into mobile/android/app/
/// 4. Add the Google Services gradle plugin (see android/build.gradle)
/// Until then, `signInWithGoogle` will just fail silently and this
/// class falls back to a "guest" flow so the rest of the app is testable.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  static const _keyLoggedIn = 'lowpoly_logged_in';
  static const _keyUsername = 'lowpoly_username';

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLoggedIn) ?? false;
  }

  Future<String?> currentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  /// Attempts real Google Sign-In. Returns true on success.
  Future<bool> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false; // user cancelled
      await _persistSession(account.displayName ?? account.email);
      return true;
    } catch (_) {
      // Not configured yet (no google-services.json) or no network.
      return false;
    }
  }

  /// Temporary fallback so you can test the app before Firebase is wired up.
  Future<bool> signInAsGuest(String name) async {
    if (name.trim().isEmpty) return false;
    await _persistSession(name.trim());
    return true;
  }

  Future<void> _persistSession(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, true);
    await prefs.setString(_keyUsername, username);
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, false);
    await prefs.remove(_keyUsername);
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
