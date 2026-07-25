import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../shared/firebase/maintainiac_auth_service.dart';

// Legacy account UI retained as a standalone, private library for source
// preservation. It is intentionally not a part of TripTrackingSettingsScreen:
// GPS settings must not own or expose Firebase backup configuration.

class _FirebaseBackupAccountPanel extends StatefulWidget {
  const _FirebaseBackupAccountPanel();

  @override
  State<_FirebaseBackupAccountPanel> createState() =>
      _FirebaseBackupAccountPanelState();
}

class _FirebaseBackupAccountPanelState
    extends State<_FirebaseBackupAccountPanel> {
  final _authService = MaintainiacAuthService();
  var _busy = false;
  String? _error;

  Future<void> _run(Future<UserCredential> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) setState(() => _error = _safeAccountError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _authService.signOut();
    } catch (_) {
      if (mounted) setState(() => _error = _safeAccountError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: _authService.authStateChanges,
    initialData: _authService.currentUser,
    builder: (context, snapshot) {
      final user = snapshot.data;
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: const Color(0xFF172023),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF5D6A71)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Mileage backup account',
              style: TextStyle(
                color: Color(0xFFE2E8EA),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              user == null
                  ? 'Sign in only if you want reviewed mileage backup. This never enables backup by itself.'
                  : 'Signed in as ${user.email ?? user.displayName ?? user.uid}. Backup remains separately opt-in below.',
              style: const TextStyle(
                color: Color(0xFFCAD2D5),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(
                _error!,
                style: const TextStyle(
                  color: Color(0xFFFFB4AB),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 7),
            if (user == null)
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _run(_authService.signInWithGoogle),
                    child: Text(_busy ? 'SIGNING IN…' : 'SIGN IN WITH GOOGLE'),
                  ),
                  if (_authService.canShowAppleSignIn)
                    OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => _run(_authService.signInWithApple),
                      child: const Text('SIGN IN WITH APPLE'),
                    ),
                ],
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: _busy ? null : _signOut,
                  child: Text(_busy ? 'SIGNING OUT…' : 'SIGN OUT'),
                ),
              ),
          ],
        ),
      );
    },
  );
}

const _safeAccountError =
    'Backup account request failed. Check your connection and try again.';
