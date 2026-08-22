class ApiConfig {
  static const String baseUrl = 'http://10.10.10.72:8000/api';

  static const String login = '$baseUrl/auth/login';
  static const String logout = '$baseUrl/auth/logout';

  static const String balance = '$baseUrl/nasabah/balance';
  static const String mutations = '$baseUrl/nasabah/mutations'
}
