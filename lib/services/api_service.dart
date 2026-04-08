import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  Future<dynamic> get(String endpoint) async {
    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}$endpoint"),
      headers: _headers(),
    );

    return _handleResponse(res);
  }

  Future<dynamic> post(String endpoint, dynamic data) async {
    final res = await http.post(
      Uri.parse("${ApiConfig.baseUrl}$endpoint"),
      headers: _headers(),
      body: jsonEncode(data),
    );

    return _handleResponse(res);
  }

  Map<String, String> _headers() {
    return {
      "Content-Type": "application/json",
      // 🔥 aquí luego metemos token
    };
  }

  dynamic _handleResponse(http.Response res) {
    final body = jsonDecode(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    } else {
      throw Exception(body.toString());
    }
  }
}