import 'package:dartz/dartz.dart';
import 'package:core/core.dart';
import 'package:domain/domain.dart';
import '../datasources/local/transaction_local_datasource.dart';
import '../datasources/remote/transaction_remote_datasource.dart';
import '../mappers/transaction_mapper.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionLocalDatasource local;
  final TransactionRemoteDatasource remote;

  TransactionRepositoryImpl({required this.local, required this.remote});

  @override
  Future<Either<Failure, List<Transaction>>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    TransactionCategory? category,
    TransactionType? type,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final models = await local.getTransactions(
        startDate: startDate,
        endDate: endDate,
        category: category?.index,
        type: type?.index,
        page: page,
        limit: limit,
      );
      return Right(models.map<Transaction>((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Transaction>> getTransactionById(String id) async {
    try {
      final model = await local.getTransactionById(id);
      if (model == null) return Left(CacheFailure(message: 'Transaction not found'));
      return Right(model.toEntity());
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Transaction>> addTransaction(Transaction transaction) async {
    try {
      final model = TransactionMapper.toModel(transaction);
      await local.saveTransaction(model);
      return Right(transaction);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Transaction>> updateTransaction(Transaction transaction) async {
    try {
      final model = TransactionMapper.toModel(transaction);
      await local.updateTransaction(model);
      return Right(transaction);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteTransaction(String id) async {
    try {
      await local.deleteTransaction(id);
      return const Right(true);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Transaction>>> getUnsyncedTransactions() async {
    try {
      final models = await local.getUnsyncedTransactions();
      return Right(models.map<Transaction>((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> syncTransactions() async {
    try {
      final unsynced = await local.getUnsyncedTransactions();
      if (unsynced.isEmpty) return const Right(true);
      final synced = await remote.syncTransactions(unsynced);
      await local.markAsSynced(
          synced.map<String>((m) => (m as TransactionModel).id).toList());
      return const Right(true);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<List<Transaction>> watchTransactions() {
    return local.watchTransactions().map(
          (models) => models.map<Transaction>((m) => (m as TransactionModel).toEntity()).toList(),
        );
  }
}
