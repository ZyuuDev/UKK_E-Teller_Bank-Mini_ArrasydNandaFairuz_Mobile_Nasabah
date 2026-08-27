import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/account_model.dart';
import '../models/mutation_model.dart';
import 'storage_service.dart';

class ApiService {
  //1. func login nasabah
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {'Accept': 'application/json'},
        body: {'username': username, 'password': password},
      );

      final body = jsonDecode(res.body);

      if (res.statusCode == 200) {
        final token = body['data']['token'];
        final role = body['data']['user']['role'];

        //hanya nasabah aja yg di aplikasi hp.
        if (role != 'Nasabah') {
          return {
            'success': false,
            'message': 'Akun ini bukan akun Nasabah. Gunakan web untuk selain Nasabah.'
          };
        }

        //save token di hp
        await StorageService.saveToken(token);
        return {'success': true};
      } else {
        return { 'success': false, 'message': 'Tidak dapat '}
      }
    }
  }

}