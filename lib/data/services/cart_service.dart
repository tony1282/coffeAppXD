import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/config/api_config.dart';
import '../../core/error/error_messages.dart';
import '../../core/error/exceptions.dart';
import '../models/cart_item_model.dart';

class CartService {
  Future<Map<String, String>> _getHeaders() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw AuthException(ErrorMessages.sessionExpired);
    }

    final token = await user.getIdToken();

    if (token == null || token.isEmpty) {
      throw AuthException(ErrorMessages.sessionExpired);
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  void _handleHttpError(http.Response response) {
    switch (response.statusCode) {
      case 400:
        throw ServerException(
          message: ErrorMessages.badRequest,
          statusCode: 400,
        );

      case 401:
        throw AuthException(
          ErrorMessages.sessionExpired,
        );

      case 403:
        throw ServerException(
          message: ErrorMessages.forbidden,
          statusCode: 403,
        );

      case 404:
        throw ServerException(
          message: ErrorMessages.notFound,
          statusCode: 404,
        );

      case 429:
        throw RateLimitException(
          ErrorMessages.rateLimited,
        );

      default:
        throw ServerException(
          message: ErrorMessages.serverError,
          statusCode: response.statusCode,
        );
    }
  }

  // ============================================================
  // GET CART
  // ============================================================
  Future<List<CartItemModel>> getCart() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/cart/'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List items = data['items'] ?? [];

        return items
            .map(
              (item) => CartItemModel(
                productId: item['product_id'],
                productName: item['product_name'],
                price: (item['price'] as num).toDouble(),
                quantity: item['quantity'],
                imageUrl: item['image_url'] ?? '',
              ),
            )
            .toList();
      }

      _handleHttpError(response);
      return [];
    } on SocketException {
      throw NetworkException(ErrorMessages.noInternet);
    } on TimeoutException {
      throw ServerException(
        message: ErrorMessages.timeout,
        statusCode: 408,
      );
    }
  }

  // ============================================================
  // SYNC CART
  // ============================================================
  Future<bool> syncCart(List<CartItemModel> items) async {
    try {
      final body = {
        'items': items
            .map(
              (item) => {
                'product_id': item.productId,
                'product_name': item.productName,
                'price': item.price,
                'quantity': item.quantity,
                'image_url': item.imageUrl,
              },
            )
            .toList(),
      };

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/cart/sync'),
            headers: await _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return true;
      }

      _handleHttpError(response);
      return false;
    } on SocketException {
      throw NetworkException(ErrorMessages.noInternet);
    } on TimeoutException {
      throw ServerException(
        message: ErrorMessages.timeout,
        statusCode: 408,
      );
    }
  }

  // ============================================================
  // ADD ITEM
  // ============================================================
  Future<bool> addItem(int productId, int quantity) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/cart/add'),
            headers: await _getHeaders(),
            body: jsonEncode({
              'product_id': productId,
              'quantity': quantity,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return true;
      }

      _handleHttpError(response);
      return false;
    } on SocketException {
      throw NetworkException(ErrorMessages.noInternet);
    } on TimeoutException {
      throw ServerException(
        message: ErrorMessages.timeout,
        statusCode: 408,
      );
    }
  }

  // ============================================================
  // UPDATE QUANTITY
  // ============================================================
  Future<bool> updateQuantity(int productId, int quantity) async {
    try {
      final response = await http
          .patch(
            Uri.parse(
              '${ApiConfig.baseUrl}/cart/$productId?quantity=$quantity',
            ),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return true;
      }

      _handleHttpError(response);
      return false;
    } on SocketException {
      throw NetworkException(ErrorMessages.noInternet);
    } on TimeoutException {
      throw ServerException(
        message: ErrorMessages.timeout,
        statusCode: 408,
      );
    }
  }

  // ============================================================
  // REMOVE ITEM
  // ============================================================
  Future<bool> removeItem(int productId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/cart/$productId'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return true;
      }

      _handleHttpError(response);
      return false;
    } on SocketException {
      throw NetworkException(ErrorMessages.noInternet);
    } on TimeoutException {
      throw ServerException(
        message: ErrorMessages.timeout,
        statusCode: 408,
      );
    }
  }

  // ============================================================
  // CLEAR CART
  // ============================================================
  Future<bool> clearCart() async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/cart/'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return true;
      }

      _handleHttpError(response);
      return false;
    } on SocketException {
      throw NetworkException(ErrorMessages.noInternet);
    } on TimeoutException {
      throw ServerException(
        message: ErrorMessages.timeout,
        statusCode: 408,
      );
    }
  }
}