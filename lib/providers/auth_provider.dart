import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api/api_client.dart';
import '../core/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _loading = true;

  UserModel? get user => _user;
  bool get loading => _loading;
  bool get isLoggedIn => _user != null;

  String? get role => _user?.role;

  String get normalizedRole {
    if (isSuperAdmin) return 'Administrateur';
    if (isCatalogManager) return 'Gestionnaire de catalogue';
    if (isEcommerceManager) return 'Responsable e-commerce';
    return _user?.role ?? 'Client';
  }

  bool get isSuperAdmin => role == 'Administrateur';
  bool get isCatalogManager => role == 'Gestionnaire de catalogue';
  bool get isEcommerceManager => role == 'Responsable e-commerce';
  bool get isAdmin => isSuperAdmin || isCatalogManager || isEcommerceManager;

  Future<void> loadUser() async {
    try {
      final token = await ApiClient.getToken();
      if (token == null) {
        _user = null;
        _loading = false;
        notifyListeners();
        return;
      }

      final res = await ApiClient.get('/api/profile');
      if (res.statusCode == 200) {
        _user = UserModel.fromJson(jsonDecode(res.body));
      } else {
        _user = null;
      }
    } catch (e) {
      print('Load user error: $e');
      _user = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final res = await ApiClient.post(
        '/api/auth/login',
        {'email': email, 'password': password},
        auth: false,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final token = data['token'];
        await ApiClient.saveToken(token);
        await loadUser();
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  // FIXED: Register matches React signup API (uses nom, prenom, email, password)
  Future<bool> register(String nom, String prenom, String email, String password) async {
    try {
      final res = await ApiClient.post(
        '/api/auth/signup',
        {
          'nom': nom,
          'prenom': prenom,
          'email': email,
          'password': password,
        },
        auth: false,
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        // After successful signup, automatically login
        return await login(email, password);
      }
      return false;
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await ApiClient.clearToken();
    _user = null;
    notifyListeners();
  }
}