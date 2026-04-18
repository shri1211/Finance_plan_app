import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

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
  }

  void _onAppResumed() {
    print("Lifecycle: App Resumed");
    _startPolling();

    // Fetch the latest transactions when the user returns
    context.read<TransactionBloc>().add(LoadTransactions(reset: true));

    // Handle session timeouts
    if (_pausedBackgroundTime != null) {
      final timeAway = DateTime.now().difference(_pausedBackgroundTime!);
      
      // If away for more than 15 minutes, logout
      if (timeAway.inMinutes >= 15) {
        print("Lifecycle: Session Expired! Logging out...");
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
    return widget.child;
  }
}
