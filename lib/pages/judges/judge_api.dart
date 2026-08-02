import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/api_config.dart';
import '../auth/judge_auth_service.dart';

class JudgeApi {
  JudgeApi._();

  static Map<String, String> get headers {
    final token = JudgeAuthSession.current?.token ?? '';
    return {
      'Authorization': 'Token $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  static Future<http.Response> get(String path) {
    return http.get(apiUri(path), headers: headers);
  }

  static Future<http.Response> post(String path, Map<String, dynamic> body) {
    return http.post(
      apiUri(path),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  static Future<Map<String, dynamic>?> getJson(String path) async {
    final res = await get(path);
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<List<dynamic>?> getList(String path) async {
    final res = await get(path);
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    return null;
  }
}
