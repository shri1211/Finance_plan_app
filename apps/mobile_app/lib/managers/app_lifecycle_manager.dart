import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';

import '../blocs/transaction/transaction_bloc.dart';
import '../blocs/auth/auth_bloc.dart';

class AppLifecycleManager extends StatefulWidget {
  final Widget child;

  const AppLifecycleManager({super.key, required this.child});

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager> with WidgetsBindingObserver {
  DateTime? _pausedBackgroundTime;
  Timer? _pollingTimer;
  
  // Biometric lock state
  bool _isAuthenticating = false;
  bool _hasAuthenticated = false;
  bool _requiresAuth = false;
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
    // Check lock on fresh start
    _checkBiometricLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkBiometricLock() async {
    final box = await Hive.openBox('settings');
    final isEnabled = box.get('biometric_enabled', defaultValue: false);
    
    if (isEnabled && !_hasAuthenticated) {
      setState(() => _requiresAuth = true);
      await _authenticate();
    } else {
      setState(() => _requiresAuth = false);
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    
    _isAuthenticating = true;
    bool authenticated = false;
    try {
      authenticated = await _auth.authenticate(
        localizedReason: 'Please authenticate to unlock FinTrack',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allows fallback to PIN/Pattern/Password
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      print("Auth error: $e");
    }

    if (authenticated) {
      setState(() {
        _hasAuthenticated = true;
        _requiresAuth = false;
        _isAuthenticating = false;
      });
    } else {
      setState(() {
        _isAuthenticating = false;
        _requiresAuth = true;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Prevent lifecycle loops caused by the native authentication dialog appearing/disappearing
    if (_isAuthenticating) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _onAppPaused();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _pollingTimer?.cancel();
        break;
    }
  }

  void _onAppPaused() {
    print("Lifecycle: App Paused");
    _pollingTimer?.cancel();
    _pausedBackgroundTime = DateTime.now();

    // Reset authentication status when app goes to background
    _hasAuthenticated = false;
  }

  void _onAppResumed() async {
    _startPolling();

    if (mounted) {
      context.read<TransactionBloc>().add(LoadTransactions(reset: true));
    }

    // Check Biometrics/PIN on resume
    await _checkBiometricLock();

    // Handle session timeouts
    if (_pausedBackgroundTime != null) {
      final timeAway = DateTime.now().difference(_pausedBackgroundTime!);
      if (timeAway.inMinutes >= 15 && mounted) {
        context.read<AuthBloc>().add(LogoutEvent());
      }
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    // Poll to sync transactions every 60 seconds while app is open
    _pollingTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      print("Lifecycle: Background Polling Executed");
      context.read<TransactionBloc>().add(SyncTransactionsEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_requiresAuth) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          backgroundColor: const Color(0xFF020617), // Deeper dark for security look
          body: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.security_rounded, size: 80, color: Colors.blueAccent),
                const SizedBox(height: 32),
                const Text(
                  'App Locked',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Use your device PIN, pattern, or biometrics to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white60),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _authenticate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Unlock with Device Security',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => context.read<AuthBloc>().add(LogoutEvent()),
                  child: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.white30, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return widget.child;
  }
}
