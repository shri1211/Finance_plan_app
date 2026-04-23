import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionRepositoryImpl.syncTransactions', () {
    test('pushes unsynced local transactions and pulls remote data', () async {
      final local = _FakeTransactionLocalDatasource();
      final remote = _FakeTransactionRemoteDatasource();
      final repository = TransactionRepositoryImpl(local: local, remote: remote);

      final unsyncedLocal = _tx(
        id: 'local-1',
        title: 'Local pending',
        amount: 120,
        isSynced: false,
      );
      local.storage[unsyncedLocal.id] = unsyncedLocal;

      remote.syncResponse = [unsyncedLocal];
      remote.getTransactionsResponse = [
        _tx(
          id: 'remote-1',
          title: 'Remote incoming',
          amount: 999,
          isSynced: false,
        ),
      ];

      final result = await repository.syncTransactions();

      expect(result.isRight(), isTrue);
      expect(remote.syncCallCount, 1);
      expect(remote.lastSyncPayload.map((e) => e.id), contains('local-1'));
      expect(local.markAsSyncedCallCount, 1);
      expect(local.markedAsSyncedIds, contains('local-1'));
      expect(remote.getTransactionsCallCount, 1);
      expect(local.storage['remote-1']?.isSynced, isTrue);
    });

    test('skips push when there are no unsynced local transactions', () async {
      final local = _FakeTransactionLocalDatasource();
      final remote = _FakeTransactionRemoteDatasource();
      final repository = TransactionRepositoryImpl(local: local, remote: remote);

      local.storage['already-synced'] = _tx(
        id: 'already-synced',
        title: 'Already synced',
        amount: 50,
        isSynced: true,
      );
      remote.getTransactionsResponse = [
        _tx(
          id: 'remote-2',
          title: 'Remote tx',
          amount: 70,
          isSynced: false,
        ),
      ];

      final result = await repository.syncTransactions();

      expect(result.isRight(), isTrue);
      expect(remote.syncCallCount, 0);
      expect(local.markAsSyncedCallCount, 0);
      expect(remote.getTransactionsCallCount, 1);
      expect(local.storage['remote-2']?.isSynced, isTrue);
    });

    test('returns failure when sync throws', () async {
      final local = _FakeTransactionLocalDatasource();
      final remote = _FakeTransactionRemoteDatasource()..throwOnSync = true;
      final repository = TransactionRepositoryImpl(local: local, remote: remote);

      local.storage['local-err'] = _tx(
        id: 'local-err',
        title: 'Needs sync',
        amount: 20,
        isSynced: false,
      );

      final result = await repository.syncTransactions();

      expect(result.isLeft(), isTrue);
      expect(local.markAsSyncedCallCount, 0);
      expect(remote.getTransactionsCallCount, 0);
    });
  });
}

TransactionModel _tx({
  required String id,
  required String title,
  required double amount,
  required bool isSynced,
}) {
  return TransactionModel(
    id: id,
    amount: amount,
    type: TransactionType.debit.index,
    category: TransactionCategory.other.index,
    title: title,
    date: DateTime(2026, 4, 20),
    isSynced: isSynced,
  );
}

class _FakeTransactionLocalDatasource implements TransactionLocalDatasource {
  final Map<String, TransactionModel> storage = {};
  int markAsSyncedCallCount = 0;
  List<String> markedAsSyncedIds = [];

  @override
  Future<void> deleteTransaction(String id) async {
    storage.remove(id);
  }

  @override
  Future<TransactionModel?> getTransactionById(String id) async {
    return storage[id];
  }

  @override
  Future<List<TransactionModel>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    int? category,
    int? type,
    int page = 1,
    int limit = 20,
  }) async {
    var result = storage.values.toList();
    if (startDate != null) {
      result = result
          .where(
            (t) =>
                t.date.isAfter(startDate) ||
                t.date.isAtSameMomentAs(startDate),
          )
          .toList();
    }
    if (endDate != null) {
      result = result
          .where(
            (t) =>
                t.date.isBefore(endDate) || t.date.isAtSameMomentAs(endDate),
          )
          .toList();
    }
    if (category != null) {
      result = result.where((t) => t.category == category).toList();
    }
    if (type != null) {
      result = result.where((t) => t.type == type).toList();
    }
    result.sort((a, b) => b.date.compareTo(a.date));
    final start = (page - 1) * limit;
    if (start >= result.length) return [];
    return result.sublist(start, (start + limit).clamp(0, result.length));
  }

  @override
  Future<List<TransactionModel>> getUnsyncedTransactions() async {
    return storage.values.where((t) => !t.isSynced).toList();
  }

  @override
  Future<void> markAsSynced(List<String> ids) async {
    markAsSyncedCallCount++;
    markedAsSyncedIds = ids;
    for (final id in ids) {
      final existing = storage[id];
      if (existing != null) {
        storage[id] = TransactionModel(
          id: existing.id,
          amount: existing.amount,
          type: existing.type,
          category: existing.category,
          title: existing.title,
          description: existing.description,
          merchant: existing.merchant,
          date: existing.date,
          isSmsParsed: existing.isSmsParsed,
          isSynced: true,
          rawSms: existing.rawSms,
        );
      }
    }
  }

  @override
  Future<void> saveTransaction(TransactionModel model) async {
    storage[model.id] = model;
  }

  @override
  Future<void> updateTransaction(TransactionModel model) async {
    storage[model.id] = model;
  }

  @override
  Stream<List<TransactionModel>> watchTransactions() {
    return Stream.value(storage.values.toList());
  }
}

class _FakeTransactionRemoteDatasource implements TransactionRemoteDatasource {
  int syncCallCount = 0;
  int getTransactionsCallCount = 0;
  bool throwOnSync = false;
  List<TransactionModel> lastSyncPayload = [];
  List<TransactionModel> syncResponse = [];
  List<TransactionModel> getTransactionsResponse = [];

  @override
  Future<TransactionModel> createTransaction(TransactionModel model) async {
    return model;
  }

  @override
  Future<void> deleteTransaction(String id) async {}

  @override
  Future<List<TransactionModel>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    int? category,
    int? type,
    int page = 1,
    int limit = 20,
  }) async {
    getTransactionsCallCount++;
    return getTransactionsResponse;
  }

  @override
  Future<List<TransactionModel>> syncTransactions(
    List<TransactionModel> unsynced,
  ) async {
    syncCallCount++;
    if (throwOnSync) {
      throw Exception('sync failed');
    }
    lastSyncPayload = unsynced;
    return syncResponse;
  }

  @override
  Future<TransactionModel> updateTransaction(TransactionModel model) async {
    return model;
  }
}
