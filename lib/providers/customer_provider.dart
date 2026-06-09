import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/customer_model.dart';
import '../services/api_service.dart';

class CustomerProvider with ChangeNotifier {
  late final ApiService _api;

  bool _loading = false;
  bool _submitting = false;
  String? _error;
  List<CustomerModel> _customers = [];

  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get error => _error;
  List<CustomerModel> get customers => _customers;

  CustomerProvider(SharedPreferences prefs) {
    _api = ApiService(prefs);
  }

  Future<void> fetchCustomers() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/customers');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List raw = data is List ? data : (data['data'] ?? []);
        _customers = raw.map((e) => CustomerModel.fromJson(e)).toList();
      } else {
        _error = 'Failed to load customers.';
      }
    } catch (_) {
      _error = 'Failed to load customers.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> saveCustomer(CustomerModel customer, {int? editId}) async {
    _submitting = true;
    _error = null;
    notifyListeners();

    try {
      final response = editId != null
          ? await _api.put('/customers/$editId', customer.toJson())
          : await _api.post('/customers', customer.toJson());

      _submitting = false;
      notifyListeners();

      if (response.statusCode == 200 || response.statusCode == 201) {
        fetchCustomers();
        return true;
      }

      final body = jsonDecode(response.body);
      _error = body['message']?.toString() ?? 'Unable to save customer.';
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Unable to save customer.';
      _submitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCustomer(int id) async {
    try {
      final response = await _api.delete('/customers/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _customers.removeWhere((c) => c.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
