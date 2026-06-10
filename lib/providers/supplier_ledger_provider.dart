import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lookup_data.dart';
import '../models/supplier_ledger_model.dart';
import '../services/api_service.dart';

class SupplierLedgerProvider with ChangeNotifier {
  late final ApiService _api;

  bool _loadingSuppliers = false;
  bool _loadingLedger = false;
  String? _error;

  List<SupplierModel> _suppliers = [];
  SupplierLedgerResponseModel? _ledgerData;

  bool get loading => _loadingSuppliers || _loadingLedger;
  bool get loadingLedger => _loadingLedger;
  String? get error => _error;
  List<SupplierModel> get suppliers => _suppliers;
  SupplierLedgerResponseModel? get ledgerData => _ledgerData;

  SupplierLedgerProvider(SharedPreferences prefs) {
    _api = ApiService(prefs);
  }

  Future<void> fetchSuppliers() async {
    _loadingSuppliers = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/suppliers');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List raw = data is List ? data : (data['data'] ?? []);
        _suppliers = raw.map((e) => SupplierModel.fromJson(e)).toList();
      } else {
        _error = 'Failed to load suppliers.';
      }
    } catch (_) {
      _error = 'Failed to load suppliers.';
    } finally {
      _loadingSuppliers = false;
      notifyListeners();
    }
  }

  Future<void> fetchLedger(int supplierId) async {
    _loadingLedger = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/supplier-ledger/$supplierId');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _ledgerData = SupplierLedgerResponseModel.fromJson(data);
      } else {
        _error = 'Failed to load supplier ledger.';
        _ledgerData = null;
      }
    } catch (_) {
      _error = 'Failed to load supplier ledger.';
      _ledgerData = null;
    } finally {
      _loadingLedger = false;
      notifyListeners();
    }
  }

  void clearLedger() {
    _ledgerData = null;
    notifyListeners();
  }
}
