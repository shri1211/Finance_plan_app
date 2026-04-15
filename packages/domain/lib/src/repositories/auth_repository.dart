import 'package:dartz/dartz.dart';
import 'package:core/core.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, User>> register({
    required String name,
    required String email,
    required String password,
  });

  Future<Either<Failure, bool>> logout();

  Future<Either<Failure, User?>> getCurrentUser();

  Future<Either<Failure, String>> refreshToken();

  Future<Either<Failure, bool>> isAuthenticated();
}
