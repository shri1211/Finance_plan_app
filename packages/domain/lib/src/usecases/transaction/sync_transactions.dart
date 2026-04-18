import 'package:dartz/dartz.dart';
import 'package:core/core.dart';
import '../../repositories/transaction_repository.dart';

class SyncTransactions extends UseCase<bool, NoParams> {
  final TransactionRepository repository;
  
  SyncTransactions(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) {
    return repository.syncTransactions();
  }
}
