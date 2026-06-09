import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sale_invoice_model.dart';
import '../models/customer_model.dart';
import '../models/lookup_data.dart';
import '../models/item.dart';
import '../services/api_service.dart';

class SalesInvoiceProvider with ChangeNotifier {
  late final ApiService _api;

  bool _loading = false;
  bool _submitting = false;
  String? _error;

  List<SaleInvoiceListModel> _invoices = [];
  List<CustomerModel> _customers = [];
  List<CategoryModel> _categories = [];
  List<ItemModel> _items = [];

  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get error => _error;
  List<SaleInvoiceListModel> get invoices => _invoices;
  List<CustomerModel> get customers => _customers;
  List<CategoryModel> get categories => _categories;
  List<ItemModel> get items => _items;

  SalesInvoiceProvider(SharedPreferences prefs) {
    _api = ApiService(prefs);
  }

  Future<List> _safeList(String endpoint) async {
    try {
      final r = await _api.get(endpoint);
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        return data is List ? data : (data['data'] ?? []);
      }
    } catch (_) {}
    return [];
  }

  /// Fetch customers, categories, and items in parallel.
  Future<void> fetchInitialData() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _safeList('/customers'),
        _safeList('/categories'),
        _safeList('/item-details'),
      ]);

      _customers = results[0].map((e) => CustomerModel.fromJson(e)).toList();
      _categories = results[1].map((e) => CategoryModel.fromJson(e)).toList();
      _items = results[2].map((e) => ItemModel.fromJson(e)).toList();
    } catch (_) {
      _error = 'Failed to load initial data.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchInvoices() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/sale-invoices');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List raw = data is List ? data : (data['data'] ?? []);
        _invoices =
            raw.map((e) => SaleInvoiceListModel.fromJson(e)).toList();
      } else {
        _error = 'Failed to load invoices.';
      }
    } catch (_) {
      _error = 'Failed to load invoices.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> saveInvoice(Map<String, dynamic> payload, {int? editId}) async {
    _submitting = true;
    _error = null;
    notifyListeners();

    try {
      final response = editId != null
          ? await _api.put('/sale-invoices/$editId', payload)
          : await _api.post('/sale-invoices', payload);

      _submitting = false;
      notifyListeners();

      if (response.statusCode == 200 || response.statusCode == 201) {
        fetchInvoices();
        return true;
      }

      final body = jsonDecode(response.body);
      _error = body['message']?.toString() ?? 'Failed to save invoice.';
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Failed to save invoice.';
      _submitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteInvoice(int id) async {
    try {
      final response = await _api.delete('/sale-invoices/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _invoices.removeWhere((inv) => inv.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
