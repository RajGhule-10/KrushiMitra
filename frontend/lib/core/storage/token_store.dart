abstract interface class TokenStore {
  Future<void> saveAccessToken(String token);

  Future<String?> getAccessToken();

  Future<void> clearAccessToken();
}
