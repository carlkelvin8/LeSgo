import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/di/local_storage_service.dart';
import '../../../core/services/biometric_unlock_service.dart';

/// Covers the entire navigator, including routes opened by notifications.
class BiometricUnlockGate extends StatefulWidget {
  const BiometricUnlockGate({
    super.key,
    required this.service,
    required this.storage,
    required this.onSignInAgain,
    required this.child,
  });

  final BiometricUnlockService service;
  final LocalStorageService storage;
  final Future<void> Function() onSignInAgain;
  final Widget child;

  @override
  State<BiometricUnlockGate> createState() => _BiometricUnlockGateState();
}

class _BiometricUnlockGateState extends State<BiometricUnlockGate>
    with WidgetsBindingObserver {
  StreamSubscription<String?>? _subscription;
  late bool _locked;
  bool _private = false;
  bool _busy = false;
  String? _error;
  int _attempt = 0;

  bool get _enabled =>
      widget.service.preferences.biometricUnlockEnabled &&
      (widget.storage.token ?? '').isNotEmpty;

  @override
  void initState() {
    super.initState();
    _locked = _enabled;
    WidgetsBinding.instance.addObserver(this);
    _subscription = widget.storage.tokenStream.listen((token) {
      if (!mounted) return;
      if ((token ?? '').isEmpty) {
        // Logged out / signed in again — nothing left to protect.
        _attempt++;
        setState(() {
          _locked = false;
          _private = false;
          _busy = false;
        });
      } else if (_enabled && !_locked && !_busy) {
        // Session restored after login while biometric unlock is on.
        setState(() => _locked = true);
        _unlock();
      }
    });
    if (_locked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_enabled) {
      if (_private || _locked) {
        setState(() {
          _private = false;
          _locked = false;
        });
      }
      return;
    }
    setState(() {
      _private = state != AppLifecycleState.resumed;
      if ((state == AppLifecycleState.paused ||
              state == AppLifecycleState.hidden) &&
          !widget.service.isAuthenticating) {
        _locked = true;
      }
    });
    if (state == AppLifecycleState.resumed && _locked && !_busy) {
      _unlock();
    }
  }

  Future<void> _unlock() async {
    if (!mounted || _busy || !_locked) return;
    final attempt = ++_attempt;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final success = await widget.service.authenticate();
      if (!mounted || attempt != _attempt) return;
      setState(() {
        final lifecycle = WidgetsBinding.instance.lifecycleState;
        _locked =
            !success ||
            lifecycle == AppLifecycleState.paused ||
            lifecycle == AppLifecycleState.hidden;
        if (!success) _error = 'Unlock cancelled. Try again to continue.';
      });
    } catch (error) {
      if (mounted && attempt == _attempt) {
        setState(() => _error = BiometricUnlockService.errorMessage(error));
      }
    } finally {
      if (mounted && attempt == _attempt) setState(() => _busy = false);
    }
  }

  Future<void> _signInAgain() async {
    setState(() => _busy = true);
    try {
      await widget.onSignInAgain();
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not sign out. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _attempt++;
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final covered = _locked || _private;
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeFocus(
          excluding: covered,
          child: Offstage(offstage: covered, child: widget.child),
        ),
        if (covered)
          Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 56,
                        color: Color(0xFF5F2D82),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'LeSgo is locked',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _error ??
                            'Use your fingerprint, Face ID, or device screen lock to continue.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _busy || _private ? null : _unlock,
                        icon: const Icon(Icons.fingerprint),
                        label: Text(_busy ? 'Authenticating…' : 'Unlock'),
                      ),
                      TextButton(
                        onPressed: _busy || _private ? null : _signInAgain,
                        child: const Text('Sign in again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
