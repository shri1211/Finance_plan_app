import 'package:dartz/dartz.dart';
import 'package:core/core.dart';
import 'package:domain/domain.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final TransactionRepository transactionRepository;

  AnalyticsRepositoryImpl({required this.transactionRepository});

  @override
  Future<Either<Failure, AnalyticsSummary>> getDailySummary(DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      final result = await transactionRepository.getTransactions(
        startDate: start,
        endDate: end,
        limit: 1000,
      );
      return result.fold(
        Left.new,
        (transactions) => Right(_computeSummary(transactions)),
      );
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MonthlyReport>> getMonthlyReport({
    required int year,
    required int month,
  }) async {
    try {
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 1);
      final result = await transactionRepository.getTransactions(
        startDate: start,
        endDate: end,
        limit: 1000,
      );
      return result.fold(
        Left.new,
        (transactions) {
          final summary = _computeSummary(transactions);
          final topExpenses = transactions
              .where((t) => t.isDebit)
              .toList()
            ..sort((a, b) => b.amount.compareTo(a.amount));
          return Right(MonthlyReport(
            year: year,
            month: month,
            summary: summary,
            topExpenses: topExpenses.take(5).toList(),
          ));
        },
      );
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MonthlyReport>>> getYearlyReport(int year) async {
    final reports = <MonthlyReport>[];
    for (int month = 1; month <= 12; month++) {
      final result = await getMonthlyReport(year: year, month: month);
      result.fold(
        (_) {},
        (report) => reports.add(report),
      );
    }
    return Right(reports);
  }

  AnalyticsSummary _computeSummary(List<Transaction> transactions) {
    double totalIncome = 0;
    double totalExpense = 0;
    final Map<TransactionCategory, double> categoryBreakdown = {};
    final Map<DateTime, _DayAcc> dailyMap = {};

    for (final t in transactions) {
      if (t.isCredit) {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
        categoryBreakdown[t.category] =
            (categoryBreakdown[t.category] ?? 0) + t.amount;
      }
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      final acc = dailyMap[day] ?? _DayAcc();
      if (t.isCredit) {
        acc.income += t.amount;
      } else {
        acc.expense += t.amount;
      }
      dailyMap[day] = acc;
    }

    final dailySpendings = dailyMap.entries.map((e) {
      return DailySpending(
        date: e.key,
        income: e.value.income,
        expense: e.value.expense,
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return AnalyticsSummary(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      balance: totalIncome - totalExpense,
      categoryBreakdown: categoryBreakdown,
      dailySpendings: dailySpendings,
    );
  }
}

class _DayAcc {
  double income = 0;
  double expense = 0;
}
