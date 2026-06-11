import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/permission.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  late final ApiService _apiService;

  UserModel? _user;
  PermissionsModel _permissions = PermissionsModel.empty();
  String? _token;
  bool _isAuthenticated = false;
  bool _loading = false;
  String? _error;

  UserModel? get user => _user;
  PermissionsModel get permissions => _permissions;
  String? get token => _token;
  bool get isAuthenticated => _isAuthenticated;
  bool get loading => _loading;
  String? get error => _error;

  AuthProvider(this._prefs) {
    _apiService = ApiService(_prefs);
    _loadStoredAuth();
  }

  // Load auth state from local storage on startup
  void _loadStoredAuth() {
    _token = _prefs.getString('token');
    
    final userJson = _prefs.getString('user');
    if (userJson != null) {
      _user = UserModel.fromJson(jsonDecode(userJson));
    }

    final permissionsJson = _prefs.getString('permissions');
    if (permissionsJson != null) {
      _permissions = PermissionsModel.fromJson(jsonDecode(permissionsJson));
    }

    _isAuthenticated = _token != null;
    debugPrint('AUTH: Initial auth check. Token present: ${_token != null}, IsAuthenticated: $_isAuthenticated');
    if (_isAuthenticated) {
      debugPrint('STATUS: LOGGED IN (from stored session)');
    } else {
      debugPrint('STATUS: NOT LOGGED IN');
    }
    notifyListeners();
  }

  // Clear authentication error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Login action — mirrors React authSlice loginUser thunk exactly
  Future<bool> login(String identifier, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    debugPrint('AUTH: Starting login attempt for $identifier');

    try {
      final response = await _apiService.post('/auth/login', {
        'identifier': identifier,
        'password': password,
      });

      debugPrint('AUTH: Server responded with status ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        _token = data['token']?.toString();
        if (_token == null) {
          debugPrint('AUTH: Login FAILED - Missing token in response');
          _error = 'Invalid server response: missing token';
          _loading = false;
          notifyListeners();
          return false;
        }

        debugPrint('AUTH: Token received successfully');

        final userRaw = data['user'] as Map<String, dynamic>? ?? {};
        _user = UserModel.fromJson(userRaw);

        final permissionsRaw = data['permissions'] as Map<String, dynamic>?;

        // Mirror React: isAdmin = user.is_admin || user.role === 'admin' || permissions.isAdmin
        final bool isAdmin = (_user?.isAdmin ?? false) ||
            (permissionsRaw?['isAdmin'] == true) ||
            (permissionsRaw?['is_admin'] == true);

        _permissions = PermissionsModel(
          modules: permissionsRaw != null && permissionsRaw['modules'] is List
              ? (permissionsRaw['modules'] as List)
                  .map((m) => ModulePermission.fromJson(m as Map<String, dynamic>))
                  .toList()
              : [],
          functionalities: permissionsRaw != null && permissionsRaw['functionalities'] is List
              ? (permissionsRaw['functionalities'] as List)
                  .map((f) => FunctionalityPermission.fromJson(f as Map<String, dynamic>))
                  .toList()
              : [],
          isAdmin: isAdmin,
        );

        // Persist to SharedPreferences (mirrors localStorage in React)
        await _prefs.setString('token', _token!);
        await _prefs.setString('user', jsonEncode(_user!.toJson()));
        await _prefs.setString('permissions', jsonEncode(_permissions.toJson()));

        _isAuthenticated = true;
        _loading = false;
        debugPrint('-----------------------------------');
        debugPrint('STATUS: LOGGED IN');
        debugPrint('AUTH: Login SUCCESSFUL. User: ${_user?.email ?? _user?.name}, IsAdmin: $isAdmin');
        debugPrint('-----------------------------------');
        notifyListeners();
        return true;
      } else {
        // Extract error message from response body
        String errorMessage = 'Login failed';
        try {
          final data = jsonDecode(response.body);
          errorMessage = data['message'] ??
              data['error'] ??
              data['msg'] ??
              'Login failed (${response.statusCode})';
        } catch (_) {
          errorMessage = 'Login failed (${response.statusCode})';
        }
        debugPrint('-----------------------------------');
        debugPrint('STATUS: NOT LOGGED IN');
        debugPrint('AUTH: Login FAILED. Error: $errorMessage');
        debugPrint('-----------------------------------');
        _error = errorMessage;
        _loading = false;
        notifyListeners();
        return false;
      }
    } on UnauthorizedException catch (e) {
      debugPrint('AUTH: Login FAILED (Unauthorized): ${e.message}');
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('AUTH: Login FAILED (Exception): $e');
      _error = 'Network error. Please check your connection.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // Refresh permissions — mirrors React refreshPermissions thunk
  Future<void> refreshPermissions() async {
    if (!_isAuthenticated) return;

    try {
      final response = await _apiService.get('/auth/me/permissions');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Mirror React formatting in refreshPermissions
        _permissions = PermissionsModel(
          modules: data['modules'] is List
              ? (data['modules'] as List)
                  .map((m) => ModulePermission.fromJson(m as Map<String, dynamic>))
                  .toList()
              : [],
          functionalities: data['functionalities'] is List
              ? (data['functionalities'] as List)
                  .map((f) => FunctionalityPermission.fromJson(f as Map<String, dynamic>))
                  .toList()
              : [],
          isAdmin: data['isAdmin'] == true || _user?.isAdmin == true,
        );

        await _prefs.setString('permissions', jsonEncode(_permissions.toJson()));
        notifyListeners();
      }
    } catch (_) {
      // Fail silently — same as React
    }
  }

  // Logout action
  Future<void> logout() async {
    await _prefs.remove('token');
    await _prefs.remove('user');
    await _prefs.remove('permissions');

    _user = null;
    _permissions = PermissionsModel.empty();
    _token = null;
    _isAuthenticated = false;
    _error = null;
    notifyListeners();
  }

  // --- PERMISSION CHECKS (matches react code) ---

  // Check if admin
  bool get isAdmin => _permissions.isAdmin || _user?.isAdmin == true;

  // Check if user has access to a specific module (case-insensitive)
  bool canAccess(String moduleName) {
    if (isAdmin) return true;
    if (_permissions.modules.isEmpty) return false;

    final normalized = moduleName.toLowerCase().trim();
    return _permissions.modules.any((m) {
      final name = (m.name ?? m.moduleName ?? m.slug ?? '').toLowerCase().trim();
      return name == normalized || name.contains(normalized) || normalized.contains(name);
    });
  }

  // Check action permission on a module
  bool can(String moduleName, String action) {
    if (isAdmin) return true;
    if (moduleName.isEmpty) return false;

    // First check module access
    if (!canAccess(moduleName)) return false;
    if (action.isEmpty) return true;

    final functionalities = _permissions.functionalities;
    final normalizedModule = moduleName.toLowerCase().trim();
    final normalizedAction = action.toLowerCase().trim();

    return functionalities.any((func) {
      final funcName = (func.name ?? func.slug ?? '').toLowerCase();
      final hasAction = funcName.contains(normalizedAction);
      
      // Verify relationship to the module (name match or ID match)
      final hasModuleRelation = funcName.contains(normalizedModule) || 
          _permissions.modules.any((m) => m.id == func.moduleId && 
              (m.name ?? m.moduleName ?? m.slug ?? '').toLowerCase().contains(normalizedModule));
              
      return hasAction && hasModuleRelation;
    });
  }

  // Check if has any of the listed actions (OR check)
  bool canAny(String moduleName, List<String> actions) {
    if (isAdmin) return true;
    return actions.any((action) => can(moduleName, action));
  }

  // Check if has all of the listed actions (AND check)
  bool canAll(String moduleName, List<String> actions) {
    if (isAdmin) return true;
    return actions.every((action) => can(moduleName, action));
  }

  // Get all actions allowed on a module
  List<String> getModuleActions(String moduleName) {
    if (isAdmin) {
      return ['create', 'read', 'update', 'delete', 'print', 'transfer'];
    }

    final functionalities = _permissions.functionalities;
    final normalizedModule = moduleName.toLowerCase().trim();
    final actions = <String>{};

    for (var func in functionalities) {
      final funcName = (func.name ?? '').toLowerCase();
      if (funcName.contains(normalizedModule)) {
        if (funcName.contains('create')) actions.add('create');
        if (funcName.contains('read')) actions.add('read');
        if (funcName.contains('update')) actions.add('update');
        if (funcName.contains('delete')) actions.add('delete');
        if (funcName.contains('print')) actions.add('print');
        if (funcName.contains('transfer')) actions.add('transfer');
      }
    }

    return actions.toList();
  }

  // Check if has any module permission
  bool hasAnyModulePermission(String moduleName) {
    if (isAdmin) return true;
    if (!canAccess(moduleName)) return false;
    return getModuleActions(moduleName).isNotEmpty;
  }
}
