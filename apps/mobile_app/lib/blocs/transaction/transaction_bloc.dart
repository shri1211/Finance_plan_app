import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:domain/domain.dart';

// Events
abstract class TransactionEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadTransactions extends TransactionEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final TransactionCategory? category;
  final TransactionType? type;
  final bool reset;

  LoadTransactions({
    this.startDate,
    this.endDate,
    this.category,
    this.type,
    this.reset = false,
  });

  @override
  List<Object?> get props => [startDate, endDate, category, type, reset];
}

class AddTransactionEvent extends TransactionEvent {
  final Transaction transaction;
  AddTransactionEvent(this.transaction);
  @override
  List<Object?> get props => [transaction];
}

class UpdateTransactionEvent extends TransactionEvent {
  final Transaction transaction;
  UpdateTransactionEvent(this.transaction);
  @override
  List<Object?> get props => [transaction];
}

class DeleteTransactionEvent extends TransactionEvent {
  final String id;
  DeleteTransactionEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class SyncTransactionsEvent extends TransactionEvent {}

// States
abstract class TransactionState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionLoaded extends TransactionState {
  final List<Transaction> transactions;
  final bool hasMore;
  final int page;

  TransactionLoaded({
    required this.transactions,
    this.hasMore = false,
    this.page = 1,
  });

  TransactionLoaded copyWith({
    List<Transaction>? transactions,
    bool? hasMore,
    int? page,
  }) {
    return TransactionLoaded(
      transactions: transactions ?? this.transactions,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
    );
  }

  @override
  List<Object?> get props => [transactions, hasMore, page];
}

class TransactionAdded extends TransactionState {
  final Transaction transaction;
  TransactionAdded(this.transaction);
  @override
  List<Object?> get props => [transaction];
}

class TransactionError extends TransactionState {
  final String message;
  TransactionError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final GetTransactions getTransactions;
  final AddTransaction addTransaction;
  final UpdateTransaction updateTransaction;
  final DeleteTransaction deleteTransaction;
  final SyncTransactions syncTransactions;

  static const int _limit = 20;

  TransactionBloc({
    required this.getTransactions,
    required this.addTransaction,
    required this.updateTransaction,
    required this.deleteTransaction,
    required this.syncTransactions,
  }) : super(TransactionInitial()) {
    on<LoadTransactions>(_onLoad);
    on<AddTransactionEvent>(_onAdd);
    on<UpdateTransactionEvent>(_onUpdate);
    on<DeleteTransactionEvent>(_onDelete);
    on<SyncTransactionsEvent>(_onSync);
  }

  Future<void> _onLoad(
    LoadTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    final currentPage = (state is TransactionLoaded && !event.reset)
        ? (state as TransactionLoaded).page
        : 1;

    if (currentPage == 1) emit(TransactionLoading());

    final result = await getTransactions(GetTransactionsParams(
      startDate: event.startDate,
      endDate: event.endDate,
      category: event.category,
      type: event.type,
      page: currentPage,
      limit: _limit,
    ));

    result.fold(
      (failure) => emit(TransactionError(failure.message)),
      (transactions) {
        final existing = (state is TransactionLoaded && !event.reset)
            ? (state as TransactionLoaded).transactions
            : <Transaction>[];
        emit(TransactionLoaded(
          transactions: [...existing, ...transactions],
          hasMore: transactions.length == _limit,
          page: currentPage + 1,
        ));
      },
    );
  }

  Future<void> _onAdd(
    AddTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    final result = await addTransaction(AddTransactionParams(event.transaction));
    result.fold(
      (failure) => emit(TransactionError(failure.message)),
      (transaction) {
        emit(TransactionAdded(transaction));
        // Reload list
        add(LoadTransactions(reset: true));
      },
    );
  }

  Future<void> _onUpdate(
    UpdateTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    final result = await updateTransaction(UpdateTransactionParams(event.transaction));
    result.fold(
      (failure) => emit(TransactionError(failure.message)),
      (_) => add(LoadTransactions(reset: true)),
    );
  }

  Future<void> _onDelete(
    DeleteTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    final result = await deleteTransaction(DeleteTransactionParams(event.id));
    result.fold(
      (failure) => emit(TransactionError(failure.message)),
      (_) {
        if (state is TransactionLoaded) {
          final current = state as TransactionLoaded;
          emit(current.copyWith(
            transactions: current.transactions
                .where((t) => t.id != event.id)
                .toList(),
          ));
        }
      },
    );
  }

  Future<void> _onSync(
    SyncTransactionsEvent event,
    Emitter<TransactionState> emit,
  ) async {
    // Actually hit the backend to sync before reloading!
    await syncTransactions(const NoParams());
    add(LoadTransactions(reset: true));
  }
}
