import 'package:dartz/dartz.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import '../../entities/analytics.dart';
import '../../repositories/analytics_repository.dart';

class GetDailySummary extends UseCase<AnalyticsSummary, GetDailySummaryParams> {
  final AnalyticsRepository repository;
  GetDailySummary(this.repository);

  @override
  Future<Either<Failure, AnalyticsSummary>> call(GetDailySummaryParams params) {
    return repository.getDailySummary(params.date);
  }
}

class GetDailySummaryParams extends Equatable {
  final DateTime date;
  const GetDailySummaryParams(this.date);

  @override
  List<Object?> get props => [date];
}

class GetMonthlyReport extends UseCase<MonthlyReport, GetMonthlyReportParams> {
  final AnalyticsRepository repository;
  GetMonthlyReport(this.repository);

  @override
  Future<Either<Failure, MonthlyReport>> call(GetMonthlyReportParams params) {
    return repository.getMonthlyReport(year: params.year, month: params.month);
  }
}

class GetMonthlyReportParams extends Equatable {
  final int year;
  final int month;
  const GetMonthlyReportParams({required this.year, required this.month});

  @override
  List<Object?> get props => [year, month];
}

class GetYearlyReport extends UseCase<List<MonthlyReport>, GetYearlyReportParams> {
  final AnalyticsRepository repository;
  GetYearlyReport(this.repository);

  @override
  Future<Either<Failure, List<MonthlyReport>>> call(GetYearlyReportParams params) {
    return repository.getYearlyReport(params.year);
  }
}

class GetYearlyReportParams extends Equatable {
  final int year;
  const GetYearlyReportParams(this.year);

  @override
  List<Object?> get props => [year];
}
