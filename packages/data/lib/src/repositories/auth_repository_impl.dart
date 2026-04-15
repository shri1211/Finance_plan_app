import 'package:dartz/dartz.dart';
import 'package:core/core.dart';
import 'package:domain/domain.dart';
import '../datasources/local/auth_local_datasource.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDatasource local;
  final AuthRemoteDatasource remote;

  AuthRepositoryImpl({required this.local, required this.remote});

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) async {
    try {
      final model = await remote.login(email: email, password: password);
      await local.cacheUser(model);
      return Right(_toEntity(model));
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final model = await remote.register(name: name, email: email, password: password);
      await local.cacheUser(model);
      return Right(_toEntity(model));
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> logout() async {
    try {
      await remote.logout();
      await local.clearUser();
      return const Right(true);
    } catch (e) {
      await local.clearUser();
      return const Right(true);
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final model = await local.getCachedUser();
      if (model == null) return const Right(null);
      return Right(_toEntity(model));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> refreshToken() async {
    try {
      final refreshTok = await local.getRefreshToken();
      if (refreshTok == null) {
        return Left(AuthFailure(message: 'No refresh token found'));
      }
      final token = await remote.refreshToken(refreshTok);
      return Right(token);
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isAuthenticated() async {
    try {
      final token = await local.getAccessToken();
      return Right(token != null && token.isNotEmpty);
    } catch (e) {
      return const Right(false);
    }
  }

  User _toEntity(UserModel model) {
    return User(
      id: model.id,
      name: model.name,
      email: model.email,
      phone: model.phone,
      avatarUrl: model.avatarUrl,
      createdAt: model.createdAt,
      isEmailVerified: model.isEmailVerified,
    );
  }
}
