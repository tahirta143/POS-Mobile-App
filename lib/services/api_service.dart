import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

// Global navigator key to handle redirects on 401 (Session Expired)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
}

class ApiService {
  final SharedPreferences _prefs;
  final String baseUrl = AppConstants.apiBaseUrl;

  ApiService(this._prefs);

  Future<Map<String, String>> _getHeaders() async {
    final token = _prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Handle common HTTP response checks
  http.Response _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      _handleLogoutRedirect();
      throw UnauthorizedException('Session expired. Please login again.');
    }
    return response;
  }

  // Triggers logout navigation
  void _handleLogoutRedirect() async {
    await _prefs.remove('token');
    await _prefs.remove('user');
    await _prefs.remove('permissions');

    // Redirect to login screen, clearing navigation history
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
  }

  // GET Request
  Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl$endpoint');
    final response = await http.get(url, headers: headers);
    return _handleResponse(response);
  }

  // POST Request
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl$endpoint');
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  // PUT Request
  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl$endpoint');
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  // DELETE Request
  Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl$endpoint');
    final response = await http.delete(url, headers: headers);
    return _handleResponse(response);
  }

  // Multipart request for file upload (create or update item)
  Future<http.Response> multipart({
    required String method, // 'POST' or 'PUT'
    required String endpoint,
    required Map<String, String> fields,
    File? file,
    String fileParamName = 'itemImage',
  }) async {
    final token = _prefs.getString('token');

    final url = Uri.parse('$baseUrl$endpoint');
    final request = http.MultipartRequest(method, url);

    // Headers
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Add fields
    request.fields.addAll(fields);

    // Add file if present
    if (file != null) {
      final stream = http.ByteStream(file.openRead());
      final length = await file.length();
      
      // Determine content type
      String extension = file.path.split('.').last.toLowerCase();
      MediaType mediaType;
      if (extension == 'png') {
        mediaType = MediaType('image', 'png');
      } else if (extension == 'jpg' || extension == 'jpeg') {
        mediaType = MediaType('image', 'jpeg');
      } else if (extension == 'gif') {
        mediaType = MediaType('image', 'gif');
      } else {
        mediaType = MediaType('image', 'jpeg');
      }

      final multipartFile = http.MultipartFile(
        fileParamName,
        stream,
        length,
        filename: file.path.split(Platform.pathSeparator).last,
        contentType: mediaType,
      );
      request.files.add(multipartFile);
    }

    // Send request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _handleResponse(response);
  }
}
