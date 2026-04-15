import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:core/core.dart';
import '../../blocs/transaction/transaction_bloc.dart';
import '../../blocs/analytics/analytics_bloc.dart';
import '../transactions/add_transaction_screen.dart';
import '../transactions/transaction_list_screen.dart';
import '../analytics/analytics_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final now = DateTime.now();
    context.read<TransactionBloc>().add(LoadTransactions(reset: true));
    context.read<AnalyticsBloc>().add(
          LoadMonthlyReport(year: now.year, month: now.month),
        );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        color: AppColors.primary,
        backgroundColor: AppColors.darkSurface,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: _buildHeader(context, now),
            ),
            // Balance card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildBalanceCard(context),
              ),
            ),
            // Quick actions
            SliverToBoxAdapter(
              child: _buildQuickActions(context),
            ),
            // Spending breakdown
            SliverToBoxAdapter(
              child: _buildSpendingBreakdown(context),
            ),
            // Recent transactions
            SliverToBoxAdapter(
              child: _buildRecentTransactionsHeader(context),
            ),
            // Transaction list
            _buildTransactionList(context),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddTransaction(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DateTime now) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Your Finances 💰',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          // Notification bell
          IconButton(
            onPressed: () {},
            icon: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        double income = 0, expense = 0;
        if (state is AnalyticsMonthlyReportLoaded) {
          income = state.report.summary.totalIncome;
          expense = state.report.summary.totalExpense;
        }
        final balance = income - expense;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, Color(0xFF9D4EDD)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Balance',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                CurrencyFormatter.formatFull(balance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _balanceStat(
                      label: 'Income',
                      amount: income,
                      icon: Icons.arrow_downward_rounded,
                      color: AppColors.income,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white24,
                  ),
                  Expanded(
                    child: _balanceStat(
                      label: 'Expense',
                      amount: expense,
                      icon: Icons.arrow_upward_rounded,
                      color: AppColors.expense,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Month label
              Text(
                _monthLabel(),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _balanceStat({
    required String label,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(label,
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(icon: Icons.add_rounded, label: 'Add', color: AppColors.primary,
          onTap: () => _openAddTransaction(context)),
      _QuickAction(icon: Icons.bar_chart_rounded, label: 'Analytics', color: AppColors.accent,
          onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              )),
      _QuickAction(icon: Icons.list_alt_rounded, label: 'All', color: AppColors.warning,
          onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TransactionListScreen()),
              )),
      _QuickAction(icon: Icons.sync_rounded, label: 'Sync', color: const Color(0xFF9D4EDD),
          onTap: () => context.read<TransactionBloc>().add(SyncTransactionsEvent())),
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: actions.map((a) => _buildActionButton(a)).toList(),
      ),
    );
  }

  Widget _buildActionButton(_QuickAction a) {
    return GestureDetector(
      onTap: a.onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: a.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: a.color.withOpacity(0.3)),
            ),
            child: Icon(a.icon, color: a.color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            a.label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingBreakdown(BuildContext context) {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        if (state is! AnalyticsMonthlyReportLoaded) return const SizedBox();
        final breakdown = state.report.summary.categoryBreakdown;
        if (breakdown.isEmpty) return const SizedBox();

        final sorted = breakdown.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top = sorted.take(4).toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Spending Breakdown'),
              const SizedBox(height: 12),
              ...top.map((e) => _buildCategoryBar(e, state.report.summary.totalExpense)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryBar(MapEntry<dynamic, double> e, double total) {
    final pct = total > 0 ? e.value / total : 0.0;
    final color = _catColor(e.key);
    final emoji = _catEmoji(e.key);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(emoji),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _catName(e.key),
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '₹${e.value.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct.clamp(0.0, 1.0),
                    backgroundColor: AppColors.darkBorder,
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: SectionHeader(
        title: 'Recent Transactions',
        actionLabel: 'See All',
        onAction: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TransactionListScreen()),
        ),
      ),
    );
  }

  Widget _buildTransactionList(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is TransactionLoading) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          );
        }
        if (state is TransactionLoaded) {
          final recent = state.transactions.take(5).toList();
          if (recent.isEmpty) {
            return const SliverToBoxAdapter(
              child: EmptyState(
                emoji: '💸',
                title: 'No transactions yet',
                subtitle: 'Add your first transaction\nto get started!',
              ),
            );
          }
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TransactionTile(
                  transaction: recent[i],
                  onDelete: () => context.read<TransactionBloc>().add(
                        DeleteTransactionEvent(recent[i].id),
                      ),
                ),
              ),
              childCount: recent.length,
            ),
          );
        }
        return const SliverToBoxAdapter(child: SizedBox());
      },
    );
  }

  void _openAddTransaction(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning ☀️';
    if (h < 17) return 'Good afternoon 🌤️';
    return 'Good evening 🌙';
  }

  String _monthLabel() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.year}';
  }

  Color _catColor(dynamic cat) {
    const colors = {
      0: Color(0xFFFF6B6B), // food
      1: Color(0xFF4ECDC4), // transport
      2: Color(0xFF45B7D1), // shopping
      3: Color(0xFFFFA07A), // entertainment
      4: Color(0xFF98D8C8), // health
      5: Color(0xFFCE93D8), // utilities
      6: Color(0xFF80CBC4), // education
      7: Color(0xFF66BB6A), // salary
      8: Color(0xFFFFCA28), // investment
      9: Color(0xFF90CAF9), // transfer
      10: Color(0xFFB0BEC5), // other
    };
    final idx = cat?.index ?? 10;
    return colors[idx] ?? const Color(0xFFB0BEC5);
  }

  String _catEmoji(dynamic cat) {
    const emojis = ['🍔', '🚗', '🛍️', '🎬', '💊', '💡', '📚', '💼', '📈', '💳', '📦'];
    final idx = cat?.index ?? 10;
    return idx < emojis.length ? emojis[idx] : '📦';
  }

  String _catName(dynamic cat) {
    const names = ['Food', 'Transport', 'Shopping', 'Entertainment', 'Health',
        'Utilities', 'Education', 'Salary', 'Investment', 'Transfer', 'Other'];
    final idx = cat?.index ?? 10;
    return idx < names.length ? names[idx] : 'Other';
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
