import 'models/login_request.dart';
import 'models/register_request.dart';
import 'models/user.dart';

abstract interface class AuthRepositoryContract {
  Future<User> register(RegisterRequest request);

  Future<User> login(LoginRequest request);

  Future<User> getCurrentUser();

  Future<void> logout();
}
