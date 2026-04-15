import 'package:dio/dio.dart';
import '../../models/user_model.dart';
import 'api_client.dart';

abstract class AuthRemoteDatasource {
  Future<UserModel> login({required String email, required String password});
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  });
  Future<void> logout();
  Future<String> refreshToken(String token);
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final ApiClient apiClient;

  AuthRemoteDatasourceImpl(this.apiClient);

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final userData = response.data['data'];
    final user = UserModel.fromJson(userData['user']);
    apiClient.setAuthToken(userData['accessToken']);
    return UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      avatarUrl: user.avatarUrl,
      createdAt: user.createdAt,
      isEmailVerified: user.isEmailVerified,
      accessToken: userData['accessToken'],
      refreshToken: userData['refreshToken'],
    );
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await apiClient.dio.post(
      '/auth/register',
      data: {'name': name, 'email': email, 'password': password},
    );
    final userData = response.data['data'];
    final user = UserModel.fromJson(userData['user']);
    apiClient.setAuthToken(userData['accessToken']);
    return UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      avatarUrl: user.avatarUrl,
      createdAt: user.createdAt,
      isEmailVerified: user.isEmailVerified,
      accessToken: userData['accessToken'],
      refreshToken: userData['refreshToken'],
    );
  }

  @override
  Future<void> logout() async {
    await apiClient.dio.post('/auth/logout');
    apiClient.clearAuthToken();
  }

  @override
  Future<String> refreshToken(String token) async {
    final response = await apiClient.dio.post(
      '/auth/refresh-token',
      data: {'refreshToken': token},
    );
    final newToken = response.data['data']['accessToken'] as String;
    apiClient.setAuthToken(newToken);
    return newToken;
  }
}
