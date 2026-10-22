import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      "https://script.google.com/macros/s/AKfycbzIX1AEQY7INDOnFHqdEtKcRbZaPcO85nr3i0oeXq-tICIVNX-vGtyBiOrqTRBy7Gjt/exec";

  // Phone number cleaner: '+' spaces ane leading '91' hatavshe
  static String _cleanPhone(String phone) {
    String clean = phone.replaceAll('+', '').replaceAll(' ', '').replaceAll('-', '').trim();
    if (clean.startsWith('91') && clean.length > 10) {
      clean = clean.substring(2);
    }
    return clean;
  }

  // Safe JSON Decoder: HTML (<!DOCTYPE) error crash prevent kare chhe
  static Map<String, dynamic> _safeDecode(http.Response response) {
    final body = response.body.trim();
    if (body.startsWith('<')) {
      return {
        'status': 'ERROR',
        'message': 'Google Web App authorization pending or access restricted. Please re-deploy as Anyone.'
      };
    }
    try {
      return jsonDecode(body);
    } catch (e) {
      return {'status': 'ERROR', 'message': e.toString()};
    }
  }

  // 1. REGISTER USER (For signup.dart)
  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String phone,
    required String gender,
    required String password,
  }) async {
    try {
      final uri = Uri.parse(baseUrl).replace(queryParameters: {
        'action': 'registerUser',
        'name': name,
        'email': email,
        'phone_number': _cleanPhone(phone),
        'gender': gender,
        'password': password,
      });
      final response = await http.get(uri);
      return _safeDecode(response);
    } catch (e) {
      return {'status': 'ERROR', 'message': e.toString()};
    }
  }

  // 2. LOGIN USER (For main.dart)
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse(baseUrl).replace(queryParameters: {
        'action': 'loginUser',
        'email': email,
        'password': password,
      });
      final response = await http.get(uri);
      return _safeDecode(response);
    } catch (e) {
      return {'status': 'ERROR', 'message': e.toString()};
    }
  }

  // 3. GET WISHLIST (For wishlist.dart)
  static Future<List<Map<String, dynamic>>> getWishlist(String userId) async {
    try {
      final uri = Uri.parse(baseUrl).replace(queryParameters: {
        'action': 'getWishlist',
        'user_id': userId,
      });
      final response = await http.get(uri);
      final decoded = _safeDecode(response);
      if (decoded['status'] == 'SUCCESS' && decoded['data'] != null) {
        return List<Map<String, dynamic>>.from(decoded['data']);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // 4. ADD TO WISHLIST
  static Future<Map<String, dynamic>> addToWishlist({
    required String userId,
    required String shoeId,
    required String shoeName,
    required int price,
    required String imageUrl,
  }) async {
    try {
      final uri = Uri.parse(baseUrl).replace(queryParameters: {
        'action': 'addToWishlist',
        'user_id': userId,
        'shoe_id': shoeId,
        'shoe_name': shoeName,
        'price': price.toString(),
        'image_url': imageUrl,
      });
      final response = await http.get(uri);
      return _safeDecode(response);
    } catch (e) {
      return {'status': 'ERROR', 'message': e.toString()};
    }
  }

  // 5. REMOVE FROM WISHLIST
  static Future<Map<String, dynamic>> removeFromWishlist({
    required String userId,
    required String shoeId,
  }) async {
    try {
      final uri = Uri.parse(baseUrl).replace(queryParameters: {
        'action': 'removeFromWishlist',
        'user_id': userId,
        'shoe_id': shoeId,
      });
      final response = await http.get(uri);
      return _safeDecode(response);
    } catch (e) {
      return {'status': 'ERROR', 'message': e.toString()};
    }
  }

  // 6. ADD TO CART (For shop.dart)
  static Future<Map<String, dynamic>> addToCart({
    required String userId,
    required String shoeId,
    required String shoeName,
    required String size,
    required int quantity,
    required int price,
  }) async {
    try {
      final uri = Uri.parse(baseUrl).replace(queryParameters: {
        'action': 'addToCart',
        'user_id': userId,
        'shoe_id': shoeId,
        'shoe_name': shoeName,
        'size': size,
        'quantity': quantity.toString(),
        'price': price.toString(),
      });
      final response = await http.get(uri);
      return _safeDecode(response);
    } catch (e) {
      return {'status': 'ERROR', 'message': e.toString()};
    }
  }

  // 7. REMOVE FROM CART (For cart.dart)
  static Future<Map<String, dynamic>> removeFromCart({
    required String userId,
    required String shoeId,
    required String size,
  }) async {
    try {
      final uri = Uri.parse(baseUrl).replace(queryParameters: {
        'action': 'removeFromCart',
        'user_id': userId,
        'shoe_id': shoeId,
        'size': size,
      });
      final response = await http.get(uri);
      return _safeDecode(response);
    } catch (e) {
      return {'status': 'ERROR', 'message': e.toString()};
    }
  }

  // 8. PLACE ORDER (For cart.dart & shop.dart)
  static Future<Map<String, dynamic>> placeOrder({
    required String orderId,
    required String userId,
    required String shoeId,
    required String shoeName,
    required String size,
    required int quantity,
    required int totalAmount,
    required String shippingAddress,
    String orderStatus = 'Confirmed',
  }) async {
    try {
      final uri = Uri.parse(baseUrl).replace(queryParameters: {
        'action': 'placeOrder',
        'order_id': orderId,
        'user_id': userId,
        'shoe_id': shoeId,
        'shoe_name': shoeName,
        'size': size,
        'quantity': quantity.toString(),
        'total_amount': totalAmount.toString(),
        'shipping_address': shippingAddress,
        'order_status': orderStatus,
      });
      final response = await http.get(uri);
      return _safeDecode(response);
    } catch (e) {
      return {'status': 'ERROR', 'message': e.toString()};
    }
  }

  // 9. UPDATE PROFILE (For profile.dart)
  static Future<Map<String, dynamic>> updateProfile({
    required String userId,
    required String name,
    required String phone,
    required String gender,
  }) async {
    try {
      final uri = Uri.parse(baseUrl).replace(queryParameters: {
        'action': 'updateProfile',
        'user_id': userId,
        'name': name,
        'phone_number': _cleanPhone(phone),
        'gender': gender,
      });
      final response = await http.get(uri);
      return _safeDecode(response);
    } catch (e) {
      return {'status': 'ERROR', 'message': e.toString()};
    }
  }

  // 10. CHANGE PASSWORD (For profile.dart)
  static Future<Map<String, dynamic>> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final uri = Uri.parse(baseUrl).replace(queryParameters: {
        'action': 'changePassword',
        'user_id': userId,
        'old_password': oldPassword,
        'new_password': newPassword,
      });
      final response = await http.get(uri);
      return _safeDecode(response);
    } catch (e) {
      return {'status': 'ERROR', 'message': e.toString()};
    }
  }

  // 11. SEND OTP (For profile.dart)
  static Future<Map<String, dynamic>> sendOtp({
    required String type,
    required String target,
    required String otp,
    required String name,
  }) async {
    try {
      final queryParams = {
        'action': 'sendOtp',
        'type': type,
        'otp': otp,
        'name': name,
      };

      if (type.toLowerCase() == 'email') {
        queryParams['email'] = target;
      } else {
        queryParams['phone'] = _cleanPhone(target);
      }

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri);
      return _safeDecode(response);
    } catch (e) {
      return {'status': 'ERROR', 'message': e.toString()};
    }
  }

  // 12. REVIEWS
  static Future<Map<String, dynamic>> addReview({
    required String shoeId,
    required String userId,
    required String userName,
    required int rating,
    required String reviewText,
  }) async {
    try {
      final uri = Uri.parse(baseUrl).replace(queryParameters: {
        'action': 'addReview',
        'shoe_id': shoeId,
        'user_id': userId,
        'user_name': userName,
        'rating': rating.toString(),
        'review_text': reviewText,
      });
      final response = await http.get(uri);
      return _safeDecode(response);
    } catch (e) {
      return {'status': 'ERROR', 'message': e.toString()};
    }
  }

  static Future<List<Map<String, dynamic>>> getReviews(String shoeId) async {
    try {
      final uri = Uri.parse(baseUrl).replace(queryParameters: {
        'action': 'getReviews',
        'shoe_id': shoeId,
      });
      final response = await http.get(uri);
      final decoded = _safeDecode(response);
      if (decoded['status'] == 'SUCCESS' && decoded['data'] != null) {
        return List<Map<String, dynamic>>.from(decoded['data']);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // 13. FETCH LIVE SHOES PRODUCTS
  static Future<List<Map<String, dynamic>>> getShoes() async {
    try {
      final uri = Uri.parse(baseUrl).replace(queryParameters: {
        'action': 'getShoes',
      });
      final response = await http.get(uri);
      final decoded = _safeDecode(response);
      if (decoded['status'] == 'SUCCESS' && decoded['data'] != null) {
        return List<Map<String, dynamic>>.from(decoded['data']);
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}