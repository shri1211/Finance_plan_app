import 'package:equatable/equatable.dart';
import 'transaction.dart';

class AnalyticsSummary extends Equatable {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final Map<TransactionCategory, double> categoryBreakdown;
  final List<DailySpending> dailySpendings;

  const AnalyticsSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.categoryBreakdown,
    required this.dailySpendings,
  });

  double get savingsRate =>
      totalIncome > 0 ? ((totalIncome - totalExpense) / totalIncome) * 100 : 0;

  @override
  List<Object?> get props =>
      [totalIncome, totalExpense, balance, categoryBreakdown];
}

class DailySpending extends Equatable {
  final DateTime date;
  final double income;
  final double expense;

  const DailySpending({
    required this.date,
    required this.income,
    required this.expense,
  });

  double get net => income - expense;

  @override
  List<Object?> get props => [date, income, expense];
}

class MonthlyReport extends Equatable {
  final int year;
  final int month;
  final AnalyticsSummary summary;
  final List<Transaction> topExpenses;

  const MonthlyReport({
    required this.year,
    required this.month,
    required this.summary,
    required this.topExpenses,
  });

  @override
  List<Object?> get props => [year, month, summary];
}
