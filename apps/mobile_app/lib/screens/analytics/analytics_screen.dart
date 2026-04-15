import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:domain/domain.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../blocs/analytics/analytics_bloc.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  int _touchedIndex = -1;
  final DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _loadMonthly();
  }

  void _loadMonthly() {
    context.read<AnalyticsBloc>().add(
          LoadMonthlyReport(year: _now.year, month: _now.month),
        );
  }

  void _loadYearly() {
    context.read<AnalyticsBloc>().add(LoadYearlyReport(_now.year));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        title: const Text('Analytics',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          onTap: (i) {
            if (i == 0 || i == 1) _loadMonthly();
            if (i == 2) _loadYearly();
          },
          tabs: const [
            Tab(text: 'Breakdown'),
            Tab(text: 'Trends'),
            Tab(text: 'Yearly'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildBreakdownTab(),
          _buildTrendTab(),
          _buildYearlyTab(),
        ],
      ),
    );
  }

  // ─── TAB 1: Breakdown (Pie + category list) ────────────────────────────────

  Widget _buildBreakdownTab() {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        if (state is AnalyticsLoading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (state is AnalyticsMonthlyReportLoaded) {
          final summary = state.report.summary;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildSummaryCards(summary),
                const SizedBox(height: 24),
                _buildPieChart(summary),
                const SizedBox(height: 20),
                _buildCategoryLegend(summary),
                const SizedBox(height: 20),
                _buildInsightsCards(summary),
              ],
            ),
          );
        }
        return const EmptyState(
          emoji: '📊',
          title: 'No data yet',
          subtitle: 'Add some transactions to see analytics',
        );
      },
    );
  }

  Widget _buildSummaryCards(AnalyticsSummary summary) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            label: 'Income',
            value: '₹${summary.totalIncome.toStringAsFixed(0)}',
            icon: Icons.arrow_downward_rounded,
            color: AppColors.income,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            label: 'Expense',
            value: '₹${summary.totalExpense.toStringAsFixed(0)}',
            icon: Icons.arrow_upward_rounded,
            color: AppColors.expense,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            label: 'Saved',
            value: '${summary.savingsRate.toStringAsFixed(1)}%',
            icon: Icons.savings_rounded,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildPieChart(AnalyticsSummary summary) {
    final breakdown = summary.categoryBreakdown;
    if (breakdown.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('No expense data',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final entries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = summary.totalExpense;

    return SizedBox(
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    _touchedIndex = response?.touchedSection?.touchedSectionIndex ?? -1;
                  });
                },
              ),
              sections: List.generate(entries.length, (i) {
                final e = entries[i];
                final color = _catColor(e.key);
                final pct = total > 0 ? (e.value / total * 100) : 0.0;
                final isTouched = i == _touchedIndex;
                return PieChartSectionData(
                  value: e.value,
                  color: color,
                  radius: isTouched ? 90 : 80,
                  title: isTouched ? '${pct.toStringAsFixed(1)}%' : '',
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  badgeWidget: isTouched
                      ? Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.darkCard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: color),
                          ),
                          child: Text(
                            _catEmoji(e.key),
                            style: const TextStyle(fontSize: 16),
                          ),
                        )
                      : null,
                  badgePositionPercentageOffset: 1.1,
                );
              }),
              centerSpaceRadius: 60,
              sectionsSpace: 2,
            ),
          ),
          // Center text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Total',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              Text('₹${total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryLegend(AnalyticsSummary summary) {
    final breakdown = summary.categoryBreakdown;
    final entries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = summary.totalExpense;

    return Column(
      children: entries.map((e) {
        final color = _catColor(e.key);
        final pct = total > 0 ? (e.value / total * 100) : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Text(_catEmoji(e.key)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _catName(e.key),
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13),
                ),
              ),
              Text(
                '${pct.toStringAsFixed(1)}%',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(width: 12),
              Text(
                '₹${e.value.toStringAsFixed(0)}',
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInsightsCards(AnalyticsSummary summary) {
    final insights = _generateInsights(summary);
    if (insights.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Insights ✨'),
        const SizedBox(height: 12),
        ...insights.map((insight) => _insightCard(insight)),
      ],
    );
  }

  Widget _insightCard(_Insight insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: insight.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: insight.color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Text(insight.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title,
                    style: TextStyle(
                        color: insight.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                const SizedBox(height: 3),
                Text(insight.body,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB 2: Trends (Line chart daily) ─────────────────────────────────────

  Widget _buildTrendTab() {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        if (state is AnalyticsLoading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (state is AnalyticsMonthlyReportLoaded) {
          final daily = state.report.summary.dailySpendings;
          if (daily.isEmpty) {
            return const EmptyState(
              emoji: '📉',
              title: 'No daily data',
              subtitle: 'Transactions will appear here as you add them',
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Daily Spending Trend'),
                const SizedBox(height: 20),
                _buildLineChart(daily),
                const SizedBox(height: 24),
                _buildDailyList(daily),
              ],
            ),
          );
        }
        return const EmptyState(
          emoji: '📈',
          title: 'No trend data',
          subtitle: 'Add transactions to see spending trends',
        );
      },
    );
  }

  Widget _buildLineChart(List<DailySpending> daily) {
    final spots = daily.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.expense);
    }).toList();

    if (spots.isEmpty) return const SizedBox();

    final maxY = daily.map((d) => d.expense).fold(0.0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.darkBorder,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (v, _) => Text(
                  '₹${v.toInt()}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < daily.length && idx % 5 == 0) {
                    return Text(
                      '${daily[idx].date.day}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 10),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: 0,
          maxY: maxY * 1.2,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.expense,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.expense.withOpacity(0.3),
                    AppColors.expense.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyList(List<DailySpending> daily) {
    final reversed = daily.reversed.take(7).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Last 7 Days'),
        const SizedBox(height: 12),
        ...reversed.map((d) => _dailyRow(d)),
      ],
    );
  }

  Widget _dailyRow(DailySpending d) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${d.date.day}',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_weekday(d.date.weekday),
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13)),
                Row(
                  children: [
                    if (d.income > 0)
                      Text('+₹${d.income.toStringAsFixed(0)} ',
                          style: const TextStyle(
                              color: AppColors.income,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    if (d.expense > 0)
                      Text('-₹${d.expense.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: AppColors.expense,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          Text(
            d.net >= 0
                ? '+₹${d.net.toStringAsFixed(0)}'
                : '-₹${d.net.abs().toStringAsFixed(0)}',
            style: TextStyle(
              color: d.net >= 0 ? AppColors.income : AppColors.expense,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB 3: Yearly (Bar chart per month) ──────────────────────────────────

  Widget _buildYearlyTab() {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        if (state is AnalyticsLoading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (state is AnalyticsYearlyReportLoaded) {
          final reports = state.reports;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: 'Year ${_now.year} Overview'),
                const SizedBox(height: 20),
                _buildBarChart(reports),
                const SizedBox(height: 24),
                _buildMonthlyList(reports),
              ],
            ),
          );
        }
        return const EmptyState(
          emoji: '📅',
          title: 'No yearly data',
          subtitle: 'Data will appear as months progress',
        );
      },
    );
  }

  Widget _buildBarChart(List<MonthlyReport> reports) {
    const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    final maxY = reports.fold(0.0, (prev, r) {
      final m = r.summary.totalIncome > r.summary.totalExpense
          ? r.summary.totalIncome
          : r.summary.totalExpense;
      return m > prev ? m : prev;
    });

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, __) {
                final label = rod.color == AppColors.income ? 'Income' : 'Expense';
                return BarTooltipItem(
                  '$label\n₹${rod.toY.toStringAsFixed(0)}',
                  const TextStyle(color: Colors.white, fontSize: 11),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  return i < months.length
                      ? Text(months[i],
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 11))
                      : const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (v, _) => Text(
                  '₹${(v / 1000).toStringAsFixed(0)}k',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 10),
                ),
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: reports.asMap().entries.map((e) {
            final r = e.value;
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: r.summary.totalIncome,
                  color: AppColors.income,
                  width: 8,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4)),
                ),
                BarChartRodData(
                  toY: r.summary.totalExpense,
                  color: AppColors.expense,
                  width: 8,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMonthlyList(List<MonthlyReport> reports) {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Monthly Breakdown'),
        const SizedBox(height: 12),
        ...reports.map((r) {
          final monthName = r.month <= 12 ? monthNames[r.month - 1] : '';
          final net = r.summary.balance;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              children: [
                Text(monthName.substring(0, 3),
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('In: ₹${r.summary.totalIncome.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  color: AppColors.income, fontSize: 12)),
                          Text('Out: ₹${r.summary.totalExpense.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  color: AppColors.expense, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${net >= 0 ? '+' : ''}₹${net.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: net >= 0 ? AppColors.income : AppColors.expense,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  List<_Insight> _generateInsights(AnalyticsSummary summary) {
    final list = <_Insight>[];
    if (summary.savingsRate >= 30) {
      list.add(_Insight('🎉', 'Great Saving!',
          'You saved ${summary.savingsRate.toStringAsFixed(1)}% this month.',
          AppColors.income));
    } else if (summary.savingsRate < 10 && summary.totalIncome > 0) {
      list.add(_Insight('⚠️', 'Low Savings',
          'Only ${summary.savingsRate.toStringAsFixed(1)}% saved. Try to target 20%+.',
          AppColors.warning));
    }
    if (summary.totalExpense > summary.totalIncome && summary.totalIncome > 0) {
      list.add(_Insight('🚨', 'Overspending',
          'Expenses exceed income by ₹${(summary.totalExpense - summary.totalIncome).toStringAsFixed(0)}.',
          AppColors.expense));
    }
    if (summary.categoryBreakdown.isNotEmpty) {
      final top = summary.categoryBreakdown.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      final pct = summary.totalExpense > 0
          ? (top.value / summary.totalExpense * 100).toStringAsFixed(1)
          : '0';
      list.add(_Insight(_catEmoji(top.key), 'Top Category',
          '$pct% of expenses on ${_catName(top.key)}', AppColors.primary));
    }
    return list;
  }

  Color _catColor(dynamic cat) {
    const colors = {
      0: Color(0xFFFF6B6B), 1: Color(0xFF4ECDC4), 2: Color(0xFF45B7D1),
      3: Color(0xFFFFA07A), 4: Color(0xFF98D8C8), 5: Color(0xFFCE93D8),
      6: Color(0xFF80CBC4), 7: Color(0xFF66BB6A), 8: Color(0xFFFFCA28),
      9: Color(0xFF90CAF9), 10: Color(0xFFB0BEC5),
    };
    final idx = (cat as TransactionCategory).index;
    return colors[idx] ?? const Color(0xFFB0BEC5);
  }

  String _catEmoji(TransactionCategory cat) {
    const e = ['🍔','🚗','🛍️','🎬','💊','💡','📚','💼','📈','💳','📦'];
    return cat.index < e.length ? e[cat.index] : '📦';
  }

  String _catName(TransactionCategory cat) {
    const n = ['Food','Transport','Shopping','Entertainment','Health',
        'Utilities','Education','Salary','Investment','Transfer','Other'];
    return cat.index < n.length ? n[cat.index] : 'Other';
  }

  String _weekday(int d) {
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return days[(d - 1).clamp(0, 6)];
  }
}

class _Insight {
  final String emoji, title, body;
  final Color color;
  const _Insight(this.emoji, this.title, this.body, this.color);
}
