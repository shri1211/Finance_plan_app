import 'package:hive/hive.dart';
import '../../models/transaction_model.dart';

abstract class TransactionLocalDatasource {
  Future<List<TransactionModel>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    int? category,
    int? type,
    int page = 1,
    int limit = 20,
  });

  Future<TransactionModel?> getTransactionById(String id);

  Future<void> saveTransaction(TransactionModel model);

  Future<void> updateTransaction(TransactionModel model);

  Future<void> deleteTransaction(String id);

  Future<List<TransactionModel>> getUnsyncedTransactions();

  Future<void> markAsSynced(List<String> ids);

  Stream<List<TransactionModel>> watchTransactions();
}

class TransactionLocalDatasourceImpl implements TransactionLocalDatasource {
  static const String boxName = 'transactions';

  Box<TransactionModel> get _box => Hive.box<TransactionModel>(boxName);

  @override
  Future<List<TransactionModel>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    int? category,
    int? type,
    int page = 1,
    int limit = 20,
  }) async {
    var all = _box.values.toList();

    if (startDate != null) {
      all = all.where((t) => t.date.isAfter(startDate) || t.date.isAtSameMomentAs(startDate)).toList();
    }
    if (endDate != null) {
      all = all.where((t) => t.date.isBefore(endDate) || t.date.isAtSameMomentAs(endDate)).toList();
    }
    if (category != null) {
      all = all.where((t) => t.category == category).toList();
    }
    if (type != null) {
      all = all.where((t) => t.type == type).toList();
    }

    all.sort((a, b) => b.date.compareTo(a.date));

    final start = (page - 1) * limit;
    if (start >= all.length) return [];
    return all.sublist(start, (start + limit).clamp(0, all.length));
  }

  @override
  Future<TransactionModel?> getTransactionById(String id) async {
    return _box.get(id);
  }

  @override
  Future<void> saveTransaction(TransactionModel model) async {
    await _box.put(model.id, model);
  }

  @override
  Future<void> updateTransaction(TransactionModel model) async {
    await _box.put(model.id, model);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _box.delete(id);
  }

  @override
  Future<List<TransactionModel>> getUnsyncedTransactions() async {
    return _box.values.where((t) => !t.isSynced).toList();
  }

  @override
  Future<void> markAsSynced(List<String> ids) async {
    for (final id in ids) {
      final model = _box.get(id);
      if (model != null) {
        // Create updated model with isSynced = true
        final updated = TransactionModel(
          id: model.id,
          amount: model.amount,
          type: model.type,
          category: model.category,
          title: model.title,
          description: model.description,
          merchant: model.merchant,
          date: model.date,
          isSmsParsed: model.isSmsParsed,
          isSynced: true,
          rawSms: model.rawSms,
        );
        await _box.put(id, updated);
      }
    }
  }

  @override
  Stream<List<TransactionModel>> watchTransactions() {
    return _box.watch().asyncMap((_) async {
      final all = _box.values.toList();
      all.sort((a, b) => b.date.compareTo(a.date));
      return all;
    });
  }
}
