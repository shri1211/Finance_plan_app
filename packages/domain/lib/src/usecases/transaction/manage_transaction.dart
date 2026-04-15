import 'package:dartz/dartz.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import '../../entities/transaction.dart';
import '../../repositories/transaction_repository.dart';

class AddTransaction extends UseCase<Transaction, AddTransactionParams> {
  final TransactionRepository repository;
  AddTransaction(this.repository);

  @override
  Future<Either<Failure, Transaction>> call(AddTransactionParams params) {
    return repository.addTransaction(params.transaction);
  }
}

class AddTransactionParams extends Equatable {
  final Transaction transaction;
  const AddTransactionParams(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class UpdateTransaction extends UseCase<Transaction, UpdateTransactionParams> {
  final TransactionRepository repository;
  UpdateTransaction(this.repository);

  @override
  Future<Either<Failure, Transaction>> call(UpdateTransactionParams params) {
    return repository.updateTransaction(params.transaction);
  }
}

class UpdateTransactionParams extends Equatable {
  final Transaction transaction;
  const UpdateTransactionParams(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class DeleteTransaction extends UseCase<bool, DeleteTransactionParams> {
  final TransactionRepository repository;
  DeleteTransaction(this.repository);

  @override
  Future<Either<Failure, bool>> call(DeleteTransactionParams params) {
    return repository.deleteTransaction(params.id);
  }
}

class DeleteTransactionParams extends Equatable {
  final String id;
  const DeleteTransactionParams(this.id);

  @override
  List<Object?> get props => [id];
}
