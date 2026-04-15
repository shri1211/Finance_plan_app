import 'package:hive/hive.dart';
import 'package:domain/domain.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 0)
class TransactionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final int type; // 0 = credit, 1 = debit

  @HiveField(3)
  final int category;

  @HiveField(4)
  final String title;

  @HiveField(5)
  final String? description;

  @HiveField(6)
  final String? merchant;

  @HiveField(7)
  final DateTime date;

  @HiveField(8)
  final bool isSmsParsed;

  @HiveField(9)
  final bool isSynced;

  @HiveField(10)
  final String? rawSms;

  TransactionModel({
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

  factory TransactionModel.fromEntity(Transaction entity) {
    return TransactionModel(
      id: entity.id,
      amount: entity.amount,
      type: entity.type.index,
      category: entity.category.index,
      title: entity.title,
      description: entity.description,
      merchant: entity.merchant,
      date: entity.date,
      isSmsParsed: entity.isSmsParsed,
      isSynced: entity.isSynced,
      rawSms: entity.rawSms,
    );
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['_id'] ?? json['id'],
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] is int
          ? json['type']
          : (json['type'] == 'credit' ? 0 : 1),
      category: json['category'] is int
          ? json['category']
          : _categoryFromString(json['category']),
      title: json['title'],
      description: json['description'],
      merchant: json['merchant'],
      date: DateTime.parse(json['date']),
      isSmsParsed: json['isSmsParsed'] ?? false,
      isSynced: json['isSynced'] ?? true,
      rawSms: json['rawSms'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'type': type == 0 ? 'credit' : 'debit',
      'category': TransactionCategory.values[category].name,
      'title': title,
      'description': description,
      'merchant': merchant,
      'date': date.toIso8601String(),
      'isSmsParsed': isSmsParsed,
      'isSynced': isSynced,
      'rawSms': rawSms,
    };
  }

  Transaction toEntity() {
    return Transaction(
      id: id,
      amount: amount,
      type: TransactionType.values[type],
      category: TransactionCategory.values[category],
      title: title,
      description: description,
      merchant: merchant,
      date: date,
      isSmsParsed: isSmsParsed,
      isSynced: isSynced,
      rawSms: rawSms,
    );
  }

  static int _categoryFromString(String? cat) {
    if (cat == null) return TransactionCategory.other.index;
    return TransactionCategory.values
            .indexWhere((e) => e.name == cat)
            .clamp(0, TransactionCategory.values.length - 1);
  }
}
