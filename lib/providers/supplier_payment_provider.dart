import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lookup_data.dart';
import '../models/supplier_payment_model.dart';
import '../services/api_service.dart';

class SupplierPaymentProvider with ChangeNotifier {
  late final ApiService _api;

  bool _loadingSuppliers = false;
  bool _loadingPurchases = false;
  bool _loadingPayments = false;
  bool _submitting = false;
  String? _error;

  List<SupplierModel> _suppliers = [];
  List<SupplierPurchaseModel> _purchases = [];
  List<SupplierPaymentModel> _payments = [];

  bool get loading => _loadingSuppliers || _loadingPurchases || _loadingPayments;
  bool get submitting => _submitting;
  String? get error => _error;
  List<SupplierModel> get suppliers => _suppliers;
  List<SupplierPurchaseModel> get purchases => _purchases;
  List<SupplierPaymentModel> get payments => _payments;

  SupplierPaymentProvider(SharedPreferences prefs) {
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

  Future<void> fetchPurchases() async {
    _loadingPurchases = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/purchases');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List raw = data is List ? data : (data['data'] ?? []);
        _purchases = raw.map((e) => SupplierPurchaseModel.fromJson(e)).toList();
      } else {
        _purchases = [];
      }
    } catch (_) {
      _purchases = [];
    } finally {
      _loadingPurchases = false;
      notifyListeners();
    }
  }

  Future<void> fetchPayments() async {
    _loadingPayments = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/supplier-payments');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List raw = data is List ? data : (data['data'] ?? []);
        _payments = raw.map((e) => SupplierPaymentModel.fromJson(e)).toList();
      } else {
        _error = 'Failed to load payment history.';
      }
    } catch (_) {
      _error = 'Failed to load payment history.';
    } finally {
      _loadingPayments = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllPageData() async {
    _error = null;
    notifyListeners();
    await Future.wait([
      fetchSuppliers(),
      fetchPurchases(),
      fetchPayments(),
    ]);
  }

  Future<bool> savePayment(SupplierPaymentModel payment, {int? editId}) async {
    _submitting = true;
    _error = null;
    notifyListeners();

    try {
      final response = editId != null
          ? await _api.put('/supplier-payments/$editId', payment.toJson())
          : await _api.post('/supplier-payments', payment.toJson());

      _submitting = false;
      notifyListeners();

      if (response.statusCode == 200 || response.statusCode == 201) {
        fetchAllPageData();
        return true;
      }

      final body = jsonDecode(response.body);
      _error = body['message']?.toString() ?? 'Unable to save payment.';
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Unable to save payment.';
      _submitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePayment(int id) async {
    try {
      final response = await _api.delete('/supplier-payments/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _payments.removeWhere((p) => p.id == id);
        notifyListeners();
        // Recalculate purchases since payment deletion updates status
        fetchPurchases();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
