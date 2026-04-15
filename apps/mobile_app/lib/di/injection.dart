import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:domain/domain.dart';
import 'package:data/data.dart';

import '../blocs/transaction/transaction_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/analytics/analytics_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ---------------------
  // External
  // ---------------------
  // Hive boxes are already opened in main.dart before this call

  // ---------------------
  // Data Sources
  // ---------------------
  sl.registerLazySingleton<ApiClient>(() => ApiClient());

  sl.registerLazySingleton<TransactionLocalDatasource>(
    () => TransactionLocalDatasourceImpl(),
  );
  sl.registerLazySingleton<TransactionRemoteDatasource>(
    () => TransactionRemoteDatasourceImpl(sl()),
  );
  sl.registerLazySingleton<AuthLocalDatasource>(
    () => AuthLocalDatasourceImpl(),
  );
  sl.registerLazySingleton<AuthRemoteDatasource>(
    () => AuthRemoteDatasourceImpl(sl()),
  );

  // ---------------------
  // Repositories
  // ---------------------
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(local: sl(), remote: sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(local: sl(), remote: sl()),
  );
  sl.registerLazySingleton<AnalyticsRepository>(
    () => AnalyticsRepositoryImpl(transactionRepository: sl()),
  );

  // ---------------------
  // Use Cases
  // ---------------------
  sl.registerLazySingleton(() => GetTransactions(sl()));
  sl.registerLazySingleton(() => AddTransaction(sl()));
  sl.registerLazySingleton(() => UpdateTransaction(sl()));
  sl.registerLazySingleton(() => DeleteTransaction(sl()));
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => GetDailySummary(sl()));
  sl.registerLazySingleton(() => GetMonthlyReport(sl()));
  sl.registerLazySingleton(() => GetYearlyReport(sl()));

  // ---------------------
  // BLoCs
  // ---------------------
  sl.registerFactory(
    () => TransactionBloc(
      getTransactions: sl(),
      addTransaction: sl(),
      updateTransaction: sl(),
      deleteTransaction: sl(),
    ),
  );
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      registerUseCase: sl(),
      logoutUseCase: sl(),
      getCurrentUser: sl(),
    ),
  );
  sl.registerFactory(
    () => AnalyticsBloc(
      getDailySummary: sl(),
      getMonthlyReport: sl(),
      getYearlyReport: sl(),
    ),
  );
}
