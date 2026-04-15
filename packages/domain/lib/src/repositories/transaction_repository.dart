import 'package:dartz/dartz.dart';
import 'package:core/core.dart';
import '../entities/transaction.dart';

abstract class TransactionRepository {
  Future<Either<Failure, List<Transaction>>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    TransactionCategory? category,
    TransactionType? type,
    int page = 1,
    int limit = 20,
  });

  Future<Either<Failure, Transaction>> getTransactionById(String id);

  Future<Either<Failure, Transaction>> addTransaction(Transaction transaction);

  Future<Either<Failure, Transaction>> updateTransaction(Transaction transaction);

  Future<Either<Failure, bool>> deleteTransaction(String id);

  Future<Either<Failure, List<Transaction>>> getUnsyncedTransactions();

  Future<Either<Failure, bool>> syncTransactions();

  Stream<List<Transaction>> watchTransactions();
}
