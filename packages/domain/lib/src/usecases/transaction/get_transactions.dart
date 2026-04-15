import 'package:dartz/dartz.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import '../../entities/transaction.dart';
import '../../repositories/transaction_repository.dart';

class GetTransactions extends UseCase<List<Transaction>, GetTransactionsParams> {
  final TransactionRepository repository;
  GetTransactions(this.repository);

  @override
  Future<Either<Failure, List<Transaction>>> call(GetTransactionsParams params) {
    return repository.getTransactions(
      startDate: params.startDate,
      endDate: params.endDate,
      category: params.category,
      type: params.type,
      page: params.page,
      limit: params.limit,
    );
  }
}

class GetTransactionsParams extends Equatable {
  final DateTime? startDate;
  final DateTime? endDate;
  final TransactionCategory? category;
  final TransactionType? type;
  final int page;
  final int limit;

  const GetTransactionsParams({
    this.startDate,
    this.endDate,
    this.category,
    this.type,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [startDate, endDate, category, type, page, limit];
}
