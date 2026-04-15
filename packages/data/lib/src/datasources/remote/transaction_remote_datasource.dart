import 'package:dio/dio.dart';
import '../../models/transaction_model.dart';
import 'api_client.dart';

abstract class TransactionRemoteDatasource {
  Future<List<TransactionModel>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    int? category,
    int? type,
    int page = 1,
    int limit = 20,
  });

  Future<TransactionModel> createTransaction(TransactionModel model);

  Future<TransactionModel> updateTransaction(TransactionModel model);

  Future<void> deleteTransaction(String id);

  Future<List<TransactionModel>> syncTransactions(List<TransactionModel> unsynced);
}

class TransactionRemoteDatasourceImpl implements TransactionRemoteDatasource {
  final ApiClient apiClient;

  TransactionRemoteDatasourceImpl(this.apiClient);

  @override
  Future<List<TransactionModel>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    int? category,
    int? type,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (startDate != null) params['startDate'] = startDate.toIso8601String();
    if (endDate != null) params['endDate'] = endDate.toIso8601String();
    if (category != null) params['category'] = category;
    if (type != null) params['type'] = type;

    final response = await apiClient.dio.get(
      '/transactions',
      queryParameters: params,
    );

    final data = response.data['data'] as List;
    return data.map((json) => TransactionModel.fromJson(json)).toList();
  }

  @override
  Future<TransactionModel> createTransaction(TransactionModel model) async {
    final response = await apiClient.dio.post(
      '/transactions',
      data: model.toJson(),
    );
    return TransactionModel.fromJson(response.data['data']);
  }

  @override
  Future<TransactionModel> updateTransaction(TransactionModel model) async {
    final response = await apiClient.dio.put(
      '/transactions/${model.id}',
      data: model.toJson(),
    );
    return TransactionModel.fromJson(response.data['data']);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await apiClient.dio.delete('/transactions/$id');
  }

  @override
  Future<List<TransactionModel>> syncTransactions(
      List<TransactionModel> unsynced) async {
    final response = await apiClient.dio.post(
      '/transactions/sync',
      data: {'transactions': unsynced.map((t) => t.toJson()).toList()},
    );
    final data = response.data['data'] as List;
    return data.map((json) => TransactionModel.fromJson(json)).toList();
  }
}
