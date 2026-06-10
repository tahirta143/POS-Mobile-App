import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/customer_model.dart';
import '../models/sale_invoice_model.dart';
import '../models/customer_payment_model.dart';
import '../services/api_service.dart';

class CustomerPaymentProvider with ChangeNotifier {
  late final ApiService _api;

  bool _loadingCustomers = false;
  bool _loadingInvoices = false;
  bool _loadingPayments = false;
  bool _loadingBookings = false;
  bool _loadingBookingPayments = false;
  bool _submitting = false;
  String? _error;

  List<CustomerModel> _customers = [];
  List<SaleInvoiceListModel> _invoices = [];
  List<CustomerPaymentModel> _payments = [];
  List<BookingModel> _bookings = [];
  List<BookingPaymentModel> _bookingPayments = [];

  bool get loading =>
      _loadingCustomers ||
      _loadingInvoices ||
      _loadingPayments ||
      _loadingBookings ||
      _loadingBookingPayments;

  bool get submitting => _submitting;
  String? get error => _error;
  List<CustomerModel> get customers => _customers;
  List<SaleInvoiceListModel> get invoices => _invoices;
  List<CustomerPaymentModel> get payments => _payments;
  List<BookingModel> get bookings => _bookings;
  List<BookingPaymentModel> get bookingPayments => _bookingPayments;

  CustomerPaymentProvider(SharedPreferences prefs) {
    _api = ApiService(prefs);
  }

  Future<void> fetchCustomers() async {
    _loadingCustomers = true;
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
      _loadingCustomers = false;
      notifyListeners();
    }
  }

  Future<void> fetchInvoices() async {
    _loadingInvoices = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/sale-invoices');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List raw = data is List ? data : (data['data'] ?? []);
        _invoices = raw.map((e) => SaleInvoiceListModel.fromJson(e)).toList();
      } else {
        _invoices = [];
      }
    } catch (_) {
      _invoices = [];
    } finally {
      _loadingInvoices = false;
      notifyListeners();
    }
  }

  Future<void> fetchCustomerPayments() async {
    _loadingPayments = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/customer-payments');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List raw = data is List ? data : (data['data'] ?? []);
        _payments = raw.map((e) => CustomerPaymentModel.fromJson(e)).toList();
      } else {
        _error = 'Failed to load customer payments.';
      }
    } catch (_) {
      _error = 'Failed to load customer payments.';
    } finally {
      _loadingPayments = false;
      notifyListeners();
    }
  }

  Future<void> fetchBookings() async {
    _loadingBookings = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/bookings');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List raw = data is List ? data : (data['data'] ?? []);
        _bookings = raw.map((e) => BookingModel.fromJson(e)).toList();
      } else {
        _bookings = [];
      }
    } catch (_) {
      _bookings = [];
    } finally {
      _loadingBookings = false;
      notifyListeners();
    }
  }

  Future<void> fetchBookingPayments() async {
    _loadingBookingPayments = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/bookings/all-payments');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List raw = data is List ? data : (data['data'] ?? []);
        _bookingPayments = raw.map((e) => BookingPaymentModel.fromJson(e)).toList();
      } else {
        _bookingPayments = [];
      }
    } catch (_) {
      _bookingPayments = [];
    } finally {
      _loadingBookingPayments = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllPageData() async {
    _error = null;
    notifyListeners();
    await Future.wait([
      fetchCustomers(),
      fetchInvoices(),
      fetchCustomerPayments(),
      fetchBookings(),
      fetchBookingPayments(),
    ]);
  }

  Future<bool> saveCustomerPayment(CustomerPaymentModel payment, {int? editId}) async {
    _submitting = true;
    _error = null;
    notifyListeners();

    try {
      final response = editId != null
          ? await _api.put('/customer-payments/$editId', payment.toJson())
          : await _api.post('/customer-payments', payment.toJson());

      _submitting = false;
      notifyListeners();

      if (response.statusCode == 200 || response.statusCode == 201) {
        fetchAllPageData();
        return true;
      }

      final body = jsonDecode(response.body);
      _error = body['message']?.toString() ?? 'Unable to save customer payment.';
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Unable to save customer payment.';
      _submitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveBookingPayment(int bookingId, Map<String, dynamic> payload) async {
    _submitting = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post('/bookings/$bookingId/payments', payload);

      _submitting = false;
      notifyListeners();

      if (response.statusCode == 200 || response.statusCode == 201) {
        fetchAllPageData();
        return true;
      }

      final body = jsonDecode(response.body);
      _error = body['message']?.toString() ?? 'Unable to save booking payment.';
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Unable to save booking payment.';
      _submitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCustomerPayment(int id) async {
    try {
      final response = await _api.delete('/customer-payments/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _payments.removeWhere((p) => p.id == id);
        notifyListeners();
        // Refresh invoices to update outstanding balances
        fetchInvoices();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteBookingPayment(int id) async {
    try {
      final response = await _api.delete('/bookings/payments/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _bookingPayments.removeWhere((p) => p.id == id);
        notifyListeners();
        // Refresh bookings to update outstanding balances
        fetchBookings();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
