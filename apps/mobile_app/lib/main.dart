import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:data/data.dart';

import 'di/injection.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/transaction/transaction_bloc.dart';
import 'blocs/analytics/analytics_bloc.dart';
import 'managers/app_lifecycle_manager.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_shell.dart';
import 'flavors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (appFlavor != null) {
    try {
      F.appFlavor = Flavor.values.firstWhere((e) => e.name == appFlavor);
    } catch (_) {
      F.appFlavor = Flavor.dev;
    }
  } else {
      F.appFlavor = Flavor.dev;
  }

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(UserModelAdapter());
  await Hive.openBox<TransactionModel>('transactions');
  await Hive.openBox<UserModel>('auth');
  await initDependencies();

  runApp(const FinTrackApp());
}

class FinTrackApp extends StatelessWidget {
  const FinTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AuthBloc>()..add(CheckAuthEvent())),
        BlocProvider(create: (_) => sl<TransactionBloc>()),
        BlocProvider(create: (_) => sl<AnalyticsBloc>()),
      ],
      child: AppLifecycleManager(
        child: MaterialApp(
        title: F.title,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        routes: {
          '/home': (_) => const HomeShell(),
          '/login': (_) => const LoginScreen(),
        },
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthLoading || state is AuthInitial) {
              return const _SplashScreen();
            }
            if (state is Authenticated) {
              return const HomeShell();
            }
            return const LoginScreen();
          },
        ),
      ),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.primary,
                    blurRadius: 40,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                size: 46,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'FinTrack',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Smart Finance Tracker',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
