// lib/services/api_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';

class ApiService {
  Future<Map<String, String>> _getHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();
    
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  Future<dynamic> get(String endpoint) async {
    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}$endpoint"),
      headers: await _getHeaders(),
    );
    return _handleResponse(res);
  }

  Future<dynamic> post(String endpoint, dynamic data) async {
    final res = await http.post(
      Uri.parse("${ApiConfig.baseUrl}$endpoint"),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    return _handleResponse(res);
  }

  Future<dynamic> put(String endpoint, dynamic data) async {
    final res = await http.put(
      Uri.parse("${ApiConfig.baseUrl}$endpoint"),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    return _handleResponse(res);
  }

  Future<dynamic> patch(String endpoint, dynamic data) async {
    final res = await http.patch(
      Uri.parse("${ApiConfig.baseUrl}$endpoint"),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    return _handleResponse(res);
  }

  Future<dynamic> delete(String endpoint) async {
    final res = await http.delete(
      Uri.parse("${ApiConfig.baseUrl}$endpoint"),
      headers: await _getHeaders(),
    );
    return _handleResponse(res);
  }

  // ─── SUBIR IMAGEN ──────────────────────────────────────────────
  Future<String> uploadImage(File imageFile) async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();

    final uri = Uri.parse("${ApiConfig.baseUrl}/products/upload-image");
    
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data['imageUrl'] ?? data['url'] ?? '';
    } else {
      throw Exception(data['message'] ?? 'Error al subir imagen');
    }
  }

  dynamic _handleResponse(http.Response res) {
    final body = jsonDecode(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    } else {
      throw Exception(body['message'] ?? body.toString());
    }
  }
}