import 'package:dartz/dartz.dart';
import 'package:core/core.dart';
import '../entities/analytics.dart';

abstract class AnalyticsRepository {
  Future<Either<Failure, AnalyticsSummary>> getDailySummary(DateTime date);

  Future<Either<Failure, MonthlyReport>> getMonthlyReport({
    required int year,
    required int month,
  });

  Future<Either<Failure, List<MonthlyReport>>> getYearlyReport(int year);
}
