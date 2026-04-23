import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:domain/domain.dart';
import '../blocs/transaction/transaction_bloc.dart';

/// Processor to read transactions that were saved in the background
/// (via SMS or Notification listeners) from a plain Map staging box
/// and convert them into properly typed Transaction objects in the main database.
class AutoCaptureProcessor {
  static const _boxName = 'auto_captured_transactions';

  static Future<void> processStagedTransactions(BuildContext context) async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        await Hive.openBox(_boxName);
      }
      
      final box = Hive.box(_boxName);
      
      if (box.isEmpty) return;

      final bloc = context.read<TransactionBloc>();
      int count = 0;
      
      for (final key in box.keys.toList()) {
        final record = box.get(key) as Map<dynamic, dynamic>?;
        if (record != null) {
          final typeIndex = record['type'] as int? ?? 1;
          final categoryIndex = record['category'] as int? ?? 10; // other

          final transaction = Transaction(
            id: record['id'] as String,
            amount: (record['amount'] as num).toDouble(),
            type: TransactionType.values[typeIndex],
            category: TransactionCategory.values[categoryIndex],
            title: record['title'] as String,
            merchant: record['merchant'] as String?,
            description: record['description'] as String?,
            date: DateTime.parse(record['date'] as String),
            isSmsParsed: record['isSmsParsed'] as bool? ?? true,
            isSynced: false,
          );
          
          bloc.add(AddTransactionEvent(transaction));
          count++;
        }
        await box.delete(key);
      }
      print('[AutoCapture] Successfully processed $count staged background transactions.');
      
    } catch (e) {
      print('[AutoCapture] Error processing staged transactions: $e');
    }
  }
}
