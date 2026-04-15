import 'package:equatable/equatable.dart';

enum TransactionType { credit, debit }

enum TransactionCategory {
  food,
  transport,
  shopping,
  entertainment,
  health,
  utilities,
  education,
  salary,
  investment,
  transfer,
  other,
}

class Transaction extends Equatable {
  final String id;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final String title;
  final String? description;
  final String? merchant;
  final DateTime date;
  final bool isSmsParsed;
  final bool isSynced;
  final String? rawSms;

  const Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.title,
    this.description,
    this.merchant,
    required this.date,
    this.isSmsParsed = false,
    this.isSynced = false,
    this.rawSms,
  });

  bool get isCredit => type == TransactionType.credit;
  bool get isDebit => type == TransactionType.debit;

  Transaction copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    TransactionCategory? category,
    String? title,
    String? description,
    String? merchant,
    DateTime? date,
    bool? isSmsParsed,
    bool? isSynced,
    String? rawSms,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      merchant: merchant ?? this.merchant,
      date: date ?? this.date,
      isSmsParsed: isSmsParsed ?? this.isSmsParsed,
      isSynced: isSynced ?? this.isSynced,
      rawSms: rawSms ?? this.rawSms,
    );
  }

  @override
  List<Object?> get props => [
        id, amount, type, category, title,
        description, merchant, date, isSmsParsed, isSynced,
      ];
}
