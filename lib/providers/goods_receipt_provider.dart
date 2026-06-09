import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/goods_receipt_model.dart';
import '../services/api_service.dart';

class GoodsReceiptProvider with ChangeNotifier {
  late final ApiService _api;

  bool _loading = false;
  bool _submitting = false;
  String? _error;
  List<PurchaseOrderModel> _pendingOrders = [];

  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get error => _error;
  List<PurchaseOrderModel> get pendingOrders => _pendingOrders;

  GoodsReceiptProvider(SharedPreferences prefs) {
    _api = ApiService(prefs);
  }

  Future<void> fetchPendingOrders() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/purchases?status=pending');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List raw = data is List ? data : (data['data'] ?? []);
        _pendingOrders = raw.map((e) => PurchaseOrderModel.fromJson(e)).toList();
      } else {
        _error = 'Failed to load pending purchase orders.';
      }
    } catch (_) {
      _error = 'Failed to load pending purchase orders.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> submitGrn({
    required int purchaseOrderId,
    required String grnNo,
    required String grnDate,
    required String remarks,
  }) async {
    _submitting = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post('/purchases/receipts', {
        'purchaseOrderId': purchaseOrderId,
        'grn_no': grnNo,
        'grn_date': grnDate,
        'remarks': remarks,
      });

      _submitting = false;
      notifyListeners();

      if (response.statusCode == 200 || response.statusCode == 201) {
        fetchPendingOrders();
        return true;
      }

      final body = jsonDecode(response.body);
      _error = body['message']?.toString() ?? 'Failed to record GRN.';
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Failed to record GRN.';
      _submitting = false;
      notifyListeners();
      return false;
    }
  }
}
