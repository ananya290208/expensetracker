import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth_screen.dart';

/// The root auth stream listener.
///
/// Persistent Sessions: Listens to FirebaseAuth.instance.authStateChanges().
/// Firebase securely persists tokens in EncryptedSharedPreferences on Android and IndexedDB on Web.
/// Seamless Launches: If a valid session token exists, directly loads [authenticatedHome].
/// Otherwise, loads the Login/Registration view [AuthScreen].
/// Secure Logout: When signOut() is called, this stream emits null and routes back to [AuthScreen].
class AuthGate extends StatelessWidget {
  final Widget authenticatedHome;

  const AuthGate({super.key, required this.authenticatedHome});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // While Firebase is restoring session from local storage
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Restoring session...'),
                ],
              ),
            ),
          );
        }

        // Active session exists: bypass login screen directly to dashboard
        if (snapshot.hasData && snapshot.data != null) {
          return authenticatedHome;
        }

        // Unauthenticated or logged out: show login/register view
        return const AuthScreen();
      },
    );
  }
}
