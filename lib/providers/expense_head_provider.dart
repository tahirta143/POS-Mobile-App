import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense_head_model.dart';
import '../services/api_service.dart';

class ExpenseHeadProvider with ChangeNotifier {
  late final ApiService _api;

  bool _loading = false;
  bool _submitting = false;
  String? _error;
  List<ExpenseHeadModel> _heads = [];

  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get error => _error;
  List<ExpenseHeadModel> get heads => _heads;

  ExpenseHeadProvider(SharedPreferences prefs) {
    _api = ApiService(prefs);
  }

  Future<void> fetchHeads() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/expense-heads');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List raw = data is List ? data : (data['data'] ?? []);
        _heads = raw.map((e) => ExpenseHeadModel.fromJson(e)).toList();
      } else {
        _error = 'Failed to load expense heads.';
      }
    } catch (_) {
      _error = 'Failed to load expense heads.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> saveHead(ExpenseHeadModel head, {int? editId}) async {
    _submitting = true;
    _error = null;
    notifyListeners();

    try {
      final response = editId != null
          ? await _api.put('/expense-heads/$editId', head.toJson())
          : await _api.post('/expense-heads', head.toJson());

      _submitting = false;
      notifyListeners();

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchHeads();
        return true;
      }

      final body = jsonDecode(response.body);
      _error = body['message']?.toString() ?? 'Unable to save expense head.';
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Unable to save expense head.';
      _submitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteHead(int id) async {
    try {
      final response = await _api.delete('/expense-heads/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _heads.removeWhere((eh) => eh.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
