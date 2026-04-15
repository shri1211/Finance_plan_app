import 'package:domain/domain.dart';

/// Smart insights engine for ai-like spending analysis
class InsightsEngine {
  /// Generate smart insights from an analytics summary
  static List<SpendingInsight> generateInsights(AnalyticsSummary summary) {
    final insights = <SpendingInsight>[];

    // Savings rate insight
    if (summary.savingsRate < 20) {
      insights.add(SpendingInsight(
        type: InsightType.warning,
        title: 'Low Savings Rate',
        description:
            'You saved only ${summary.savingsRate.toStringAsFixed(1)}% this period. '
            'Try to target at least 20%.',
        emoji: '⚠️',
      ));
    } else if (summary.savingsRate >= 40) {
      insights.add(SpendingInsight(
        type: InsightType.positive,
        title: 'Excellent Savings!',
        description:
            'You saved ${summary.savingsRate.toStringAsFixed(1)}% this period. Keep it up!',
        emoji: '🎉',
      ));
    }

    // Top spending category
    if (summary.categoryBreakdown.isNotEmpty) {
      final topCat = summary.categoryBreakdown.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      final pct = summary.totalExpense > 0
          ? (topCat.value / summary.totalExpense * 100)
          : 0.0;
      insights.add(SpendingInsight(
        type: InsightType.info,
        title: 'Top Spending: ${_categoryName(topCat.key)}',
        description:
            '${pct.toStringAsFixed(1)}% of your expenses went to ${_categoryName(topCat.key)}. '
            'That\'s ₹${topCat.value.toStringAsFixed(0)}.',
        emoji: _categoryEmoji(topCat.key),
      ));
    }

    // Spending vs income
    if (summary.totalExpense > summary.totalIncome) {
      insights.add(SpendingInsight(
        type: InsightType.alert,
        title: 'Spending Exceeds Income',
        description:
            'You spent ₹${(summary.totalExpense - summary.totalIncome).toStringAsFixed(0)} '
            'more than you earned. Review your budget.',
        emoji: '🚨',
      ));
    }

    // High spending days
    final highDays = summary.dailySpendings
        .where((d) => d.expense > (summary.totalExpense / summary.dailySpendings.length) * 2)
        .length;
    if (highDays > 0 && summary.dailySpendings.isNotEmpty) {
      insights.add(SpendingInsight(
        type: InsightType.warning,
        title: '$highDays High-Spend Days',
        description:
            'You had $highDays days with unusually high spending. Consider setting daily limits.',
        emoji: '📊',
      ));
    }

    return insights;
  }

  /// Detect potential subscription patterns
  static List<String> detectSubscriptions(List<Transaction> transactions) {
    final merchantCounts = <String, int>{};
    for (final t in transactions) {
      if (t.merchant != null && t.isDebit) {
        merchantCounts[t.merchant!] = (merchantCounts[t.merchant!] ?? 0) + 1;
      }
    }
    return merchantCounts.entries
        .where((e) => e.value >= 2)
        .map((e) => e.key)
        .toList();
  }

  static String _categoryName(TransactionCategory cat) {
    switch (cat) {
      case TransactionCategory.food: return 'Food';
      case TransactionCategory.transport: return 'Transport';
      case TransactionCategory.shopping: return 'Shopping';
      case TransactionCategory.entertainment: return 'Entertainment';
      case TransactionCategory.health: return 'Health';
      case TransactionCategory.utilities: return 'Utilities';
      case TransactionCategory.education: return 'Education';
      case TransactionCategory.salary: return 'Salary';
      case TransactionCategory.investment: return 'Investment';
      case TransactionCategory.transfer: return 'Transfer';
      case TransactionCategory.other: return 'Other';
    }
  }

  static String _categoryEmoji(TransactionCategory cat) {
    switch (cat) {
      case TransactionCategory.food: return '🍔';
      case TransactionCategory.transport: return '🚗';
      case TransactionCategory.shopping: return '🛍️';
      case TransactionCategory.entertainment: return '🎬';
      case TransactionCategory.health: return '💊';
      case TransactionCategory.utilities: return '💡';
      case TransactionCategory.education: return '📚';
      case TransactionCategory.salary: return '💼';
      case TransactionCategory.investment: return '📈';
      case TransactionCategory.transfer: return '💳';
      case TransactionCategory.other: return '📦';
    }
  }
}

enum InsightType { positive, info, warning, alert }

class SpendingInsight {
  final InsightType type;
  final String title;
  final String description;
  final String emoji;

  const SpendingInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.emoji,
  });
}
