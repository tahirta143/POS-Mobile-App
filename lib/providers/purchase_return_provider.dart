import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/purchase_return_model.dart';
import '../services/api_service.dart';

class PurchaseReturnProvider with ChangeNotifier {
  late final ApiService _api;

  bool _loading = false;
  bool _submitting = false;
  String? _error;

  List<PurchaseModel> _purchases = [];
  List<PurchaseReturnModel> _recentReturns = [];

  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get error => _error;
  List<PurchaseModel> get purchases => _purchases;
  List<PurchaseReturnModel> get recentReturns => _recentReturns;

  PurchaseReturnProvider(SharedPreferences prefs) {
    _api = ApiService(prefs);
  }

  Future<void> fetchPurchases() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/purchases');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List raw = data is List ? data : (data['data'] ?? []);
        _purchases = raw.map((e) => PurchaseModel.fromJson(e)).toList();
      } else {
        _error = 'Failed to load purchase history.';
      }
    } catch (_) {
      _error = 'Failed to load purchase history.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRecentReturns() async {
    _loading = true;
    notifyListeners();

    try {
      final response = await _api.get('/purchase-returns');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List raw = data is List ? data : (data['data'] ?? []);
        _recentReturns = raw.map((e) => PurchaseReturnModel.fromJson(e)).toList();
      }
    } catch (_) {
      _recentReturns = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> submitReturn({
    required int purchaseId,
    required int supplierId,
    required List<Map<String, dynamic>> items,
    int? editId,
  }) async {
    _submitting = true;
    _error = null;
    notifyListeners();

    final payload = {
      'purchaseId': purchaseId,
      'supplierId': supplierId,
      'returnDate': DateTime.now().toIso8601String().substring(0, 10),
      'items': items,
      'reason': 'Purchase return',
    };

    try {
      final response = editId != null
          ? await _api.put('/purchase-returns/$editId', payload)
          : await _api.post('/purchase-returns', payload);

      _submitting = false;
      notifyListeners();

      if (response.statusCode == 200 || response.statusCode == 201) {
        fetchRecentReturns();
        return true;
      }

      final body = jsonDecode(response.body);
      _error = body['message']?.toString() ?? 'Failed to save return.';
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Failed to save return.';
      _submitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteReturn(int id) async {
    try {
      final response = await _api.delete('/purchase-returns/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _recentReturns.removeWhere((r) => r.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
