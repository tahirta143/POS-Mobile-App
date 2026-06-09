import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sales_return_model.dart';
import '../services/api_service.dart';

class SalesReturnProvider with ChangeNotifier {
  late final ApiService _api;

  bool _loading = false;
  bool _submitting = false;
  String? _error;

  List<SaleInvoiceModel> _saleInvoices = [];
  List<SalesReturnModel> _recentReturns = [];

  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get error => _error;
  List<SaleInvoiceModel> get saleInvoices => _saleInvoices;
  List<SalesReturnModel> get recentReturns => _recentReturns;

  SalesReturnProvider(SharedPreferences prefs) {
    _api = ApiService(prefs);
  }

  Future<void> fetchSaleInvoices() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/sale-invoices');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List raw = data is List ? data : (data['data'] ?? []);
        _saleInvoices = raw.map((e) => SaleInvoiceModel.fromJson(e)).toList();
      } else {
        _error = 'Failed to load sale invoices.';
      }
    } catch (_) {
      _error = 'Failed to load sale invoices.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRecentReturns() async {
    _loading = true;
    notifyListeners();

    try {
      final response = await _api.get('/sale-returns');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List raw = data is List ? data : (data['data'] ?? []);
        _recentReturns = raw.map((e) => SalesReturnModel.fromJson(e)).toList();
      }
    } catch (_) {
      _recentReturns = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> submitReturn({
    required int saleInvoiceId,
    required int? customerId,
    required List<Map<String, dynamic>> items,
    required double discount,
    required double totalAmount,
    int? editId,
  }) async {
    _submitting = true;
    _error = null;
    notifyListeners();

    final payload = {
      'saleInvoiceId': saleInvoiceId,
      'customerId': customerId,
      'returnDate': DateTime.now().toIso8601String().substring(0, 10),
      'items': items,
      'discount': discount,
      'totalAmount': totalAmount,
      'reason': 'Sales return',
    };

    try {
      final response = editId != null
          ? await _api.put('/sale-returns/$editId', payload)
          : await _api.post('/sale-returns', payload);

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
      final response = await _api.delete('/sale-returns/$id');
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
