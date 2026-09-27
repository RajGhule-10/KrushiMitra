import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import 'models/login_request.dart';
import 'models/register_request.dart';
import 'models/token_response.dart';
import 'models/user.dart';

class AuthApi {
  AuthApi(this._apiClient);

  final ApiClient _apiClient;

  Future<User> register(RegisterRequest request) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.authRegister,
      data: request.toJson(),
    );

    return User.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TokenResponse> login(LoginRequest request) async {
    final response = await _apiClient.dio.post(
      ApiEndpoints.authLogin,
      data: request.toJson(),
    );

    return TokenResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<User> getCurrentUser() async {
    final response = await _apiClient.dio.get(ApiEndpoints.authMe);

    return User.fromJson(response.data as Map<String, dynamic>);
  }
}
