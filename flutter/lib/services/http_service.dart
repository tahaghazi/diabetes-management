import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HttpService {
  static final HttpService _instance = HttpService._internal();
  final http.Client _client = http.Client();
  String? _accessToken;
  String? _refreshToken;

  factory HttpService() {
    return _instance;
  }

  HttpService._internal();

  http.Client get client => _client;

  void setTokens(String accessToken, String refreshToken) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  String? getAccessToken() {
    return _accessToken;
  }

  String? getRefreshToken() {
    return _refreshToken;
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  // دالة جديدة لتسجيل الخروج
  Future<void> logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_email');
    await prefs.remove('account_type');
    await prefs.remove('first_name');
    await prefs.remove('last_name');
    await prefs.remove('specialization');
    await prefs.remove('medical_history');
    clearTokens();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<bool> refreshAccessToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? refreshToken = prefs.getString('refresh_token');

    if (refreshToken == null) {
      debugPrint("No refresh token available in SharedPreferences.");
      return false;
    }

    try {
      var response = await _client.post(
        Uri.parse('https://diabetesmanagement.pythonanywhere.com/api/token/refresh/'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({'refresh': refreshToken}),
      );

      debugPrint("Refresh Token Response Status: ${response.statusCode}");
      debugPrint("Refresh Token Response Body: ${response.body}");

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        String newAccessToken = data['access'];
        _accessToken = newAccessToken;

        await prefs.setString('access_token', newAccessToken);
        debugPrint("Access token refreshed successfully: $newAccessToken");
        return true;
      } else {
        debugPrint("Failed to refresh token: ${response.body}");
        await prefs.remove('access_token');
        await prefs.remove('refresh_token');
        clearTokens();
        return false;
      }
    } catch (e) {
      debugPrint("Error refreshing token: $e");
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      clearTokens();
      return false;
    }
  }

  Future<http.Response?> makeRequest({
    required String method,
    required Uri url,
    Map<String, String>? headers,
    dynamic body,
    BuildContext? context, 
  }) async {
    headers ??= {};
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token'); 
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    } else {
      debugPrint("No access token available, proceeding without Authorization header.");
    }

    String? bodyString;
    if (body != null) {
      if (headers['Content-Type']?.contains('application/json') == true) {
        if (body is String) {
          bodyString = body;
        } else {
          bodyString = jsonEncode(body);
        }
      } else {
        bodyString = body.toString();
      }
    }

    debugPrint('Request Headers: $headers');
    debugPrint('Request Body: $bodyString');

    http.Response response;
    if (method.toUpperCase() == 'GET') {
      response = await _client.get(url, headers: headers);
    } else if (method.toUpperCase() == 'POST') {
      response = await _client.post(url, headers: headers, body: bodyString);
    } else if (method.toUpperCase() == 'PUT') {
      response = await _client.put(url, headers: headers, body: bodyString);
    } else if (method.toUpperCase() == 'DELETE') {
      response = await _client.delete(url, headers: headers);
    } else {
      throw Exception('Unsupported HTTP method');
    }

    debugPrint('Response Status: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');

    if (response.statusCode == 401) {
      debugPrint("Access token expired, attempting to refresh...");
      bool refreshed = await refreshAccessToken();
      if (refreshed) {
        headers['Authorization'] = 'Bearer $_accessToken';
        if (body != null) {
          if (headers['Content-Type']?.contains('application/json') == true) {
            if (body is String) {
              bodyString = body;
            } else {
              bodyString = jsonEncode(body);
            }
          } else {
            bodyString = body.toString();
          }
        }
        debugPrint('Retrying Request Headers: $headers');
        debugPrint('Retrying Request Body: $bodyString');
        if (method.toUpperCase() == 'GET') {
          response = await _client.get(url, headers: headers);
        } else if (method.toUpperCase() == 'POST') {
          response = await _client.post(url, headers: headers, body: bodyString);
        } else if (method.toUpperCase() == 'PUT') {
          response = await _client.put(url, headers: headers, body: bodyString);
        } else if (method.toUpperCase() == 'DELETE') {
          response = await _client.delete(url, headers: headers);
        } else {
          throw Exception('Unsupported HTTP method');
        }
        debugPrint('Retry Response Status: ${response.statusCode}');
        debugPrint('Retry Response Body: ${response.body}');
      } else {
        debugPrint("Failed to refresh token, logging out...");
        if (context != null) {
          await logout(context);
        }
        return null;
      }
    }

    return response;
  }
}