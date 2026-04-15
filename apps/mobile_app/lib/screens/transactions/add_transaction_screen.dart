import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:domain/domain.dart';
import 'package:ui_kit/ui_kit.dart';
import '../../blocs/transaction/transaction_bloc.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? existing;
  const AddTransactionScreen({super.key, this.existing});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _merchantCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  TransactionType _type = TransactionType.debit;
  TransactionCategory _category = TransactionCategory.other;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final t = widget.existing!;
      _titleCtrl.text = t.title;
      _amountCtrl.text = t.amount.toString();
      _merchantCtrl.text = t.merchant ?? '';
      _descCtrl.text = t.description ?? '';
      _type = t.type;
      _category = t.category;
      _date = t.date;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _merchantCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return BlocListener<TransactionBloc, TransactionState>(
      listener: (context, state) {
        if (state is TransactionAdded || state is TransactionLoaded) {
          if (state is TransactionLoaded) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(
          backgroundColor: AppColors.darkSurface,
          elevation: 0,
          title: Text(
            isEditing ? 'Edit Transaction' : 'Add Transaction',
            style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type toggle
                _buildTypeToggle(),
                const SizedBox(height: 24),
                // Amount
                const Text('Amount', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    prefixText: '₹  ',
                    prefixStyle: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: _type == TransactionType.credit
                          ? AppColors.income
                          : AppColors.expense,
                    ),
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: const TextStyle(color: AppColors.darkBorder),
                  ),
                  validator: (v) {
                    if (v?.isEmpty == true) return 'Enter amount';
                    if (double.tryParse(v!) == null) return 'Invalid amount';
                    return null;
                  },
                ),
                const Divider(color: AppColors.darkBorder),
                const SizedBox(height: 20),
                // Title
                TextFormField(
                  controller: _titleCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    prefixIcon: Icon(Icons.title_rounded,
                        color: AppColors.textSecondary),
                  ),
                  validator: (v) =>
                      v?.isEmpty == true ? 'Enter a title' : null,
                ),
                const SizedBox(height: 12),
                // Category
                _buildCategoryDropdown(),
                const SizedBox(height: 12),
                // Merchant
                TextFormField(
                  controller: _merchantCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Merchant (optional)',
                    prefixIcon:
                        Icon(Icons.store_outlined, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 12),
                // Date picker
                _buildDatePicker(context),
                const SizedBox(height: 12),
                // Description
                TextFormField(
                  controller: _descCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_rounded,
                        color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 32),
                // Save button
                BlocBuilder<TransactionBloc, TransactionState>(
                  builder: (context, state) {
                    final loading = state is TransactionLoading;
                    return GradientButton(
                      label: isEditing ? 'Update Transaction' : 'Save Transaction',
                      isLoading: loading,
                      icon: Icons.check_rounded,
                      gradientColors: _type == TransactionType.credit
                          ? [AppColors.income, const Color(0xFF00B4D8)]
                          : [AppColors.expense, const Color(0xFFFF9A3C)],
                      onPressed: _save,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          _typeBtn(TransactionType.debit, 'Expense', Icons.arrow_upward_rounded,
              AppColors.expense),
          _typeBtn(TransactionType.credit, 'Income', Icons.arrow_downward_rounded,
              AppColors.income),
        ],
      ),
    );
  }

  Widget _typeBtn(TransactionType type, String label, IconData icon, Color color) {
    final selected = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: selected ? color : AppColors.textSecondary, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : AppColors.textSecondary,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    const categories = TransactionCategory.values;
    const emojis = ['🍔', '🚗', '🛍️', '🎬', '💊', '💡', '📚', '💼', '📈', '💳', '📦'];
    const names = ['Food', 'Transport', 'Shopping', 'Entertainment', 'Health',
        'Utilities', 'Education', 'Salary', 'Investment', 'Transfer', 'Other'];

    return DropdownButtonFormField<TransactionCategory>(
      value: _category,
      dropdownColor: AppColors.darkSurface,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: const InputDecoration(
        labelText: 'Category',
        prefixIcon: Icon(Icons.category_outlined, color: AppColors.textSecondary),
      ),
      items: List.generate(categories.length, (i) {
        return DropdownMenuItem(
          value: categories[i],
          child: Text('${emojis[i]}  ${names[i]}'),
        );
      }),
      onChanged: (v) => setState(() => _category = v ?? _category),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.primary,
                surface: AppColors.darkSurface,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) setState(() => _date = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Date',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  Text(
                    _formatDate(_date),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountCtrl.text);
    final transaction = Transaction(
      id: widget.existing?.id ?? const Uuid().v4(),
      amount: amount,
      type: _type,
      category: _category,
      title: _titleCtrl.text.trim(),
      description:
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      merchant: _merchantCtrl.text.trim().isEmpty
          ? null
          : _merchantCtrl.text.trim(),
      date: _date,
    );

    if (widget.existing != null) {
      context.read<TransactionBloc>().add(UpdateTransactionEvent(transaction));
    } else {
      context.read<TransactionBloc>().add(AddTransactionEvent(transaction));
    }
    Navigator.of(context).pop();
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
