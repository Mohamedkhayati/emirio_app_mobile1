import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = 'http://192.168.1.14:8080';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<String?> getToken() async {
    return await _getToken();
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  static Future<Map<String, String>> _headers({bool auth = true, bool isMultipart = false}) async {
    final headers = <String, String>{};
    if (auth) {
      final token = await _getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<http.Response> get(String path, {bool auth = true}) async {
    final headers = await _headers(auth: auth);
    return http.get(Uri.parse('$baseUrl$path'), headers: headers);
  }

  static Future<http.Response> post(String path, Map<String, dynamic> body,
      {bool auth = true}) async {
    final headers = await _headers(auth: auth);
    headers['Content-Type'] = 'application/json';
    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> put(String path, Map<String, dynamic> body,
      {bool auth = true}) async {
    final headers = await _headers(auth: auth);
    headers['Content-Type'] = 'application/json';
    return http.put(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> patch(String path, {Map<String, dynamic>? body, bool auth = true}) async {
    final headers = await _headers(auth: auth);
    headers['Content-Type'] = 'application/json';
    return http.patch(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  static Future<http.Response> delete(String path, {bool auth = true}) async {
    final headers = await _headers(auth: auth);
    return http.delete(Uri.parse('$baseUrl$path'), headers: headers);
  }

  // Article Multipart POST - FIXED
  static Future<http.Response> postArticleMultipart(
      String path,
      String dataJson,
      List<File>? images,
      ) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('POST', uri);

    final token = await _getToken();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    // IMPORTANT: Send data as a JSON string field
    request.fields['data'] = dataJson;

    // Add images with correct content type
    if (images != null && images.isNotEmpty) {
      for (int i = 0; i < images.length; i++) {
        final file = images[i];
        if (await file.exists()) {
          final extension = file.path.split('.').last.toLowerCase();
          MediaType mediaType;

          if (extension == 'jpg' || extension == 'jpeg') {
            mediaType = MediaType.parse('image/jpeg');
          } else if (extension == 'png') {
            mediaType = MediaType.parse('image/png');
          } else {
            mediaType = MediaType.parse('image/jpeg');
          }

          final multipartFile = await http.MultipartFile.fromPath(
            'images', // Field name
            file.path,
            contentType: mediaType,
          );
          request.files.add(multipartFile);
        }
      }
    }

    print('📡 Sending request to: $path');
    print('📡 Data: $dataJson');

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    print('📡 Status: ${response.statusCode}');
    print('📡 Response: ${response.body}');
    return response;
  }

  static Future<http.Response> putArticleMultipart(
      String path,
      String dataJson,
      List<File>? images,
      ) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('PUT', uri);

    final token = await _getToken();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    request.fields['data'] = dataJson;

    if (images != null && images.isNotEmpty) {
      for (final file in images) {
        if (await file.exists()) {
          final extension = file.path.split('.').last.toLowerCase();
          MediaType mediaType = extension == 'png'
              ? MediaType.parse('image/png')
              : MediaType.parse('image/jpeg');

          final multipartFile = await http.MultipartFile.fromPath(
            'images',
            file.path,
            contentType: mediaType,
          );
          request.files.add(multipartFile);
        }
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return response;
  }

  // Variation Multipart POST - FIXED
  static Future<http.Response> postVariationMultipart(
      String path,
      String dataJson,
      List<File>? images,
      File? model3d,
      ) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('POST', uri);

    final token = await _getToken();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    // Send data as a field
    request.fields['data'] = dataJson;

    // Add images with correct content type
    if (images != null && images.isNotEmpty) {
      for (final file in images) {
        if (await file.exists()) {
          final extension = file.path.split('.').last.toLowerCase();
          MediaType mediaType = extension == 'png'
              ? MediaType.parse('image/png')
              : MediaType.parse('image/jpeg');

          final multipartFile = await http.MultipartFile.fromPath(
            'images',
            file.path,
            contentType: mediaType,
          );
          request.files.add(multipartFile);
        }
      }
    }

    // Add 3D model
    if (model3d != null && await model3d.exists()) {
      final modelFile = await http.MultipartFile.fromPath(
        'model3d',
        model3d.path,
        contentType: MediaType.parse('model/gltf-binary'), // For .glb files
      );
      request.files.add(modelFile);
    }

    print('📡 Sending variation request to: $path');
    print('📡 Data: $dataJson');
    print('📡 Images: ${images?.length ?? 0}');

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    print('📡 Status: ${response.statusCode}');
    print('📡 Response: ${response.body}');
    return response;
  }

  static Future<http.Response> putVariationMultipart(
      String path,
      String dataJson,
      List<File>? images,
      File? model3d,
      ) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('PUT', uri);

    final token = await _getToken();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    request.fields['data'] = dataJson;

    if (images != null && images.isNotEmpty) {
      for (final file in images) {
        if (await file.exists()) {
          final extension = file.path.split('.').last.toLowerCase();
          MediaType mediaType = extension == 'png'
              ? MediaType.parse('image/png')
              : MediaType.parse('image/jpeg');

          final multipartFile = await http.MultipartFile.fromPath(
            'images',
            file.path,
            contentType: mediaType,
          );
          request.files.add(multipartFile);
        }
      }
    }

    if (model3d != null && await model3d.exists()) {
      final modelFile = await http.MultipartFile.fromPath(
        'model3d',
        model3d.path,
        contentType: MediaType.parse('model/gltf-binary'),
      );
      request.files.add(modelFile);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return response;
  }

  static String getFullImageUrl(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    if (url.startsWith('/api')) return '$baseUrl$url';
    return '$baseUrl/$url';
  }
  // Add these methods to your ApiClient class

  static Future<http.Response> postMultipart(
      String path,
      Map<String, String> fields,
      List<File>? files,
      ) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('POST', uri);

    final token = await _getToken();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    // Add all fields
    for (final entry in fields.entries) {
      request.fields[entry.key] = entry.value;
    }

    // Add files
    if (files != null && files.isNotEmpty) {
      for (final file in files) {
        if (await file.exists()) {
          final extension = file.path.split('.').last.toLowerCase();
          MediaType mediaType;

          if (extension == 'jpg' || extension == 'jpeg') {
            mediaType = MediaType.parse('image/jpeg');
          } else if (extension == 'png') {
            mediaType = MediaType.parse('image/png');
          } else if (extension == 'glb' || extension == 'gltf') {
            mediaType = MediaType.parse('model/gltf-binary');
          } else {
            mediaType = MediaType.parse('application/octet-stream');
          }

          final multipartFile = await http.MultipartFile.fromPath(
            'files',
            file.path,
            contentType: mediaType,
          );
          request.files.add(multipartFile);
        }
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return response;
  }

  static Future<http.Response> putMultipart(
      String path,
      Map<String, String> fields,
      List<File>? files,
      ) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('PUT', uri);

    final token = await _getToken();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    // Add all fields
    for (final entry in fields.entries) {
      request.fields[entry.key] = entry.value;
    }

    // Add files
    if (files != null && files.isNotEmpty) {
      for (final file in files) {
        if (await file.exists()) {
          final extension = file.path.split('.').last.toLowerCase();
          MediaType mediaType;

          if (extension == 'jpg' || extension == 'jpeg') {
            mediaType = MediaType.parse('image/jpeg');
          } else if (extension == 'png') {
            mediaType = MediaType.parse('image/png');
          } else if (extension == 'glb' || extension == 'gltf') {
            mediaType = MediaType.parse('model/gltf-binary');
          } else {
            mediaType = MediaType.parse('application/octet-stream');
          }

          final multipartFile = await http.MultipartFile.fromPath(
            'files',
            file.path,
            contentType: mediaType,
          );
          request.files.add(multipartFile);
        }
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return response;
  }
}