import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:domain/domain.dart';

/// Chart data helpers for analytics screens
class ChartDataHelper {
  /// Build PieChart sections for category breakdown
  static List<PieChartSectionData> buildPieSections(
    Map<TransactionCategory, double> breakdown, {
    double total = 0,
  }) {
    if (breakdown.isEmpty) return [];

    final effectiveTotal =
        total > 0 ? total : breakdown.values.fold(0.0, (a, b) => a + b);

    final colors = _categoryColors;
    final entries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.map((e) {
      final pct =
          effectiveTotal > 0 ? (e.value / effectiveTotal * 100) : 0.0;
      final color = colors[e.key] ?? _defaultColor;
      return PieChartSectionData(
        value: e.value,
        color: color,
        title: '${pct.toStringAsFixed(1)}%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  /// Build BarChart groups for monthly summary
  static List<BarChartGroupData> buildMonthlyBarGroups(
      List<MonthlyReport> reports) {
    return reports.asMap().entries.map((entry) {
      final i = entry.key;
      final r = entry.value;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: r.summary.totalIncome,
            color: _incomeColor,
            width: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: r.summary.totalExpense,
            color: _expenseColor,
            width: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }

  /// Build LineChart spots for daily spending trend
  static List<FlSpot> buildDailyTrendSpots(List<DailySpending> daily) {
    return daily.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.expense);
    }).toList();
  }

  static const Map<TransactionCategory, Color> _categoryColors = {
    TransactionCategory.food: Color(0xFFFF6B6B),
    TransactionCategory.transport: Color(0xFF4ECDC4),
    TransactionCategory.shopping: Color(0xFF45B7D1),
    TransactionCategory.entertainment: Color(0xFFFFA07A),
    TransactionCategory.health: Color(0xFF98D8C8),
    TransactionCategory.utilities: Color(0xFFCE93D8),
    TransactionCategory.education: Color(0xFF80CBC4),
    TransactionCategory.salary: Color(0xFF66BB6A),
    TransactionCategory.investment: Color(0xFFFFCA28),
    TransactionCategory.transfer: Color(0xFF90CAF9),
    TransactionCategory.other: Color(0xFFB0BEC5),
  };

  static const Color _defaultColor = Color(0xFFB0BEC5);
  static const Color _incomeColor = Color(0xFF66BB6A);
  static const Color _expenseColor = Color(0xFFEF5350);

  static Color getCategoryColor(TransactionCategory cat) =>
      _categoryColors[cat] ?? _defaultColor;

  static String getCategoryName(TransactionCategory cat) {
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

  static String getCategoryEmoji(TransactionCategory cat) {
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

