import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:domain/domain.dart';

// Events
abstract class AnalyticsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadDailySummary extends AnalyticsEvent {
  final DateTime date;
  LoadDailySummary(this.date);
  @override
  List<Object?> get props => [date];
}

class LoadMonthlyReport extends AnalyticsEvent {
  final int year;
  final int month;
  LoadMonthlyReport({required this.year, required this.month});
  @override
  List<Object?> get props => [year, month];
}

class LoadYearlyReport extends AnalyticsEvent {
  final int year;
  LoadYearlyReport(this.year);
  @override
  List<Object?> get props => [year];
}

// States
abstract class AnalyticsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AnalyticsInitial extends AnalyticsState {}
class AnalyticsLoading extends AnalyticsState {}

class AnalyticsDailySummaryLoaded extends AnalyticsState {
  final AnalyticsSummary summary;
  AnalyticsDailySummaryLoaded(this.summary);
  @override
  List<Object?> get props => [summary];
}

class AnalyticsMonthlyReportLoaded extends AnalyticsState {
  final MonthlyReport report;
  AnalyticsMonthlyReportLoaded(this.report);
  @override
  List<Object?> get props => [report];
}

class AnalyticsYearlyReportLoaded extends AnalyticsState {
  final List<MonthlyReport> reports;
  AnalyticsYearlyReportLoaded(this.reports);
  @override
  List<Object?> get props => [reports];
}

class AnalyticsError extends AnalyticsState {
  final String message;
  AnalyticsError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final GetDailySummary getDailySummary;
  final GetMonthlyReport getMonthlyReport;
  final GetYearlyReport getYearlyReport;

  AnalyticsBloc({
    required this.getDailySummary,
    required this.getMonthlyReport,
    required this.getYearlyReport,
  }) : super(AnalyticsInitial()) {
    on<LoadDailySummary>(_onLoadDaily);
    on<LoadMonthlyReport>(_onLoadMonthly);
    on<LoadYearlyReport>(_onLoadYearly);
  }

  Future<void> _onLoadDaily(
      LoadDailySummary event, Emitter<AnalyticsState> emit) async {
    emit(AnalyticsLoading());
    final result = await getDailySummary(GetDailySummaryParams(event.date));
    result.fold(
      (failure) => emit(AnalyticsError(failure.message)),
      (summary) => emit(AnalyticsDailySummaryLoaded(summary)),
    );
  }

  Future<void> _onLoadMonthly(
      LoadMonthlyReport event, Emitter<AnalyticsState> emit) async {
    emit(AnalyticsLoading());
    final result = await getMonthlyReport(
      GetMonthlyReportParams(year: event.year, month: event.month),
    );
    result.fold(
      (failure) => emit(AnalyticsError(failure.message)),
      (report) => emit(AnalyticsMonthlyReportLoaded(report)),
    );
  }

  Future<void> _onLoadYearly(
      LoadYearlyReport event, Emitter<AnalyticsState> emit) async {
    emit(AnalyticsLoading());
    final result =
        await getYearlyReport(GetYearlyReportParams(event.year));
    result.fold(
      (failure) => emit(AnalyticsError(failure.message)),
      (reports) => emit(AnalyticsYearlyReportLoaded(reports)),
    );
  }
}
