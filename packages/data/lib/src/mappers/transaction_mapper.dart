import 'package:domain/domain.dart';
import '../models/transaction_model.dart';

class TransactionMapper {
  static TransactionModel toModel(Transaction entity) {
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

  static Transaction toEntity(TransactionModel model) => model.toEntity();
}
