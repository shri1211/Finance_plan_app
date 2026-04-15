import 'package:hive/hive.dart';
import '../../models/user_model.dart';

abstract class AuthLocalDatasource {
  Future<UserModel?> getCachedUser();
  Future<void> cacheUser(UserModel user);
  Future<void> clearUser();
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
}

class AuthLocalDatasourceImpl implements AuthLocalDatasource {
  static const String boxName = 'auth';
  static const String userKey = 'current_user';

  Box<UserModel> get _box => Hive.box<UserModel>(boxName);

  @override
  Future<UserModel?> getCachedUser() async {
    return _box.get(userKey);
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    await _box.put(userKey, user);
  }

  @override
  Future<void> clearUser() async {
    await _box.delete(userKey);
  }

  @override
  Future<String?> getAccessToken() async {
    return _box.get(userKey)?.accessToken;
  }

  @override
  Future<String?> getRefreshToken() async {
    return _box.get(userKey)?.refreshToken;
  }
}
