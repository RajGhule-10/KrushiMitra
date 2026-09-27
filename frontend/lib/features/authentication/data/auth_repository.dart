import '../../../core/storage/token_store.dart';
import 'auth_api.dart';
import 'models/login_request.dart';
import 'models/register_request.dart';
import 'models/token_response.dart';
import 'models/user.dart';
import 'auth_repository_contract.dart';

class AuthRepository implements AuthRepositoryContract {
  AuthRepository({required AuthApi api, required TokenStore tokenStore})
    : _api = api,
      _tokenStore = tokenStore;

  final AuthApi _api;
  final TokenStore _tokenStore;

  @override
  Future<User> register(RegisterRequest request) {
    return _api.register(request);
  }

  @override
  Future<User> login(LoginRequest request) async {
    final TokenResponse token = await _api.login(request);

    await _tokenStore.saveAccessToken(token.accessToken);

    return _api.getCurrentUser();
  }

  @override
  Future<User> getCurrentUser() {
    return _api.getCurrentUser();
  }

  @override
  Future<void> logout() async {
    await _tokenStore.clearAccessToken();
  }
}
