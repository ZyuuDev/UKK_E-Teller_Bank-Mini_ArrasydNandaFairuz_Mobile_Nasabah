class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'BANK_API_URL',
    defaultValue: 'https://skansaba-bankmini.web.id/api',
  );
}
