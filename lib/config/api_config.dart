class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'BANK_API_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );
}
