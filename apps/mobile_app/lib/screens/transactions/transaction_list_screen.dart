import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:domain/domain.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../blocs/transaction/transaction_bloc.dart';
import 'add_transaction_screen.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  TransactionType? _filterType;
  TransactionCategory? _filterCategory;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _load({bool reset = false}) {
    context.read<TransactionBloc>().add(
          LoadTransactions(
            type: _filterType,
            category: _filterCategory,
            reset: reset,
          ),
        );
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      final state = context.read<TransactionBloc>().state;
      if (state is TransactionLoaded && state.hasMore) {
        _load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        title: const Text(
          'All Transactions',
          style: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded,
                color: AppColors.textPrimary),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Active filters
          if (_filterType != null || _filterCategory != null)
            _buildActiveFilters(),
          // List
          Expanded(
            child: BlocBuilder<TransactionBloc, TransactionState>(
              builder: (context, state) {
                if (state is TransactionLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                if (state is TransactionLoaded) {
                  if (state.transactions.isEmpty) {
                    return const EmptyState(
                      emoji: '🔍',
                      title: 'No transactions found',
                      subtitle: 'Try adjusting your filters',
                    );
                  }
                  return ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.transactions.length +
                        (state.hasMore ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == state.transactions.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                                color: AppColors.primary),
                          ),
                        );
                      }
                      final t = state.transactions[i];
                      return TransactionTile(
                        transaction: t,
                        onTap: () => _openEdit(context, t),
                        onDelete: () => context.read<TransactionBloc>().add(
                              DeleteTransactionEvent(t.id),
                            ),
                      );
                    },
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => const AddTransactionScreen()),
        ),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.darkSurface,
      child: Row(
        children: [
          const Text('Filters: ',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
          if (_filterType != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: CategoryChip(
                label: _filterType == TransactionType.credit
                    ? 'Income'
                    : 'Expense',
                color: _filterType == TransactionType.credit
                    ? AppColors.income
                    : AppColors.expense,
                emoji: _filterType == TransactionType.credit ? '📥' : '📤',
              ),
            ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              setState(() {
                _filterType = null;
                _filterCategory = null;
              });
              _load(reset: true);
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: AppColors.primary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Transactions',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Type',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                _filterChip('All', null == _filterType, () {
                  setState(() => _filterType = null);
                  _load(reset: true);
                  Navigator.pop(context);
                }),
                const SizedBox(width: 8),
                _filterChip('Income', _filterType == TransactionType.credit,
                    () {
                  setState(() => _filterType = TransactionType.credit);
                  _load(reset: true);
                  Navigator.pop(context);
                }),
                const SizedBox(width: 8),
                _filterChip('Expense', _filterType == TransactionType.debit,
                    () {
                  setState(() => _filterType = TransactionType.debit);
                  _load(reset: true);
                  Navigator.pop(context);
                }),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.2)
              : AppColors.darkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.darkBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _openEdit(BuildContext context, Transaction t) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(existing: t),
      ),
    );
  }
}
