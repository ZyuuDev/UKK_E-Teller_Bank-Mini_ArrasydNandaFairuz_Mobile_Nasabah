import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/account_model.dart';
import '../models/mutation_model.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int status;
  ApiException(this.message, [this.status = 0]);
  @override
  String toString() => message;
}

class ApiService {
  static Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    if (kReleaseMode && uri.scheme != 'https')
      throw ApiException('Alamat server rilis harus menggunakan HTTPS.');
    final token = authenticated ? await StorageService.getToken() : null;
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    try {
      final response =
          await (method == 'GET'
                  ? http.get(uri, headers: headers)
                  : http.post(
                      uri,
                      headers: headers,
                      body: jsonEncode(body ?? {}),
                    ))
              .timeout(const Duration(seconds: 20));
      if (response.statusCode == 204) return {};
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 401 && authenticated)
        await StorageService.clearToken();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errors = payload['errors'] as Map<String, dynamic>?;
        final message = errors == null
            ? payload['message']?.toString()
            : errors.values.expand((value) => value as List).join(' ');
        throw ApiException(message ?? 'Permintaan gagal.', response.statusCode);
      }
      return payload;
    } on TimeoutException {
      throw ApiException(
        'Server belum merespons. Periksa koneksi dan coba lagi.',
      );
    } on http.ClientException {
      throw ApiException('Tidak dapat menghubungi server bank mini.');
    } on FormatException {
      throw ApiException('Respons server tidak sesuai format aplikasi.');
    }
  }

  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    final result = await request(
      'POST',
      '/auth/login',
      authenticated: false,
      body: {'username': username, 'password': password, 'client': 'mobile'},
    );
    final data = Map<String, dynamic>.from(result['data']);
    final user = Map<String, dynamic>.from(data['user']);
    if (user['role'] != 'student')
      throw ApiException('Aplikasi ini khusus siswa.');
    await StorageService.saveToken(data['token'] as String);
    return user;
  }

  static Future<Map<String, dynamic>> me() async =>
      Map<String, dynamic>.from((await request('GET', '/auth/me'))['data']);
  static Future<AccountModel> profile() async => AccountModel.fromJson(
    Map<String, dynamic>.from(
      (await request('GET', '/student/profile'))['data'],
    ),
  );
  static Future<MutationPage> mutations(int page) async =>
      MutationPage.fromJson(
        Map<String, dynamic>.from(
          (await request('GET', '/student/mutations?page=$page'))['data'],
        ),
      );

  static Future<Map<String, dynamic>> changePassword(
    String current,
    String password,
    String confirmation,
  ) async {
    return Map<String, dynamic>.from(
      (await request(
        'POST',
        '/auth/password',
        body: {
          'current_password': current,
          'password': password,
          'password_confirmation': confirmation,
        },
      ))['data'],
    );
  }

  static Future<void> logout() async {
    try {
      await request('POST', '/auth/logout');
    } finally {
      await StorageService.clearToken();
    }
  }
}