class DashboardStatItem {
  final double value;
  final double change;

  DashboardStatItem({required this.value, required this.change});
}

class BookingItem {
  final int id;
  final String? customerName;
  final String? mobileNo;
  final String? bookingDate;
  final double payable;
  final String bookingStatus;

  BookingItem({
    required this.id,
    this.customerName,
    this.mobileNo,
    this.bookingDate,
    required this.payable,
    required this.bookingStatus,
  });

  factory BookingItem.fromJson(Map<String, dynamic> json) {
    return BookingItem(
      id: json['id'],
      customerName: json['customer_name'] ?? 'Unknown',
      mobileNo: json['mobile_no'] ?? '—',
      bookingDate: json['booking_date'],
      payable: double.tryParse((json['payable'] ?? json['total'] ?? 0).toString()) ?? 0.0,
      bookingStatus: json['booking_status'] ?? 'Pending',
    );
  }
}

class SalesInvoiceItem {
  final int id;
  final String? customerName;
  final String? mobile;
  final double payable;
  final String status;

  SalesInvoiceItem({
    required this.id,
    this.customerName,
    this.mobile,
    required this.payable,
    required this.status,
  });

  factory SalesInvoiceItem.fromJson(Map<String, dynamic> json) {
    return SalesInvoiceItem(
      id: json['id'],
      customerName: json['customer_name'] ?? 'Unknown',
      mobile: json['mobile'] ?? '—',
      payable: double.tryParse((json['payable'] ?? json['total'] ?? 0).toString()) ?? 0.0,
      status: json['status'] ?? 'Completed',
    );
  }
}

class SalesPeriodChartItem {
  final String periodLabel;
  final double sales;
  final double expenses;

  SalesPeriodChartItem({
    required this.periodLabel,
    required this.sales,
    required this.expenses,
  });

  factory SalesPeriodChartItem.fromJson(Map<String, dynamic> json) {
    return SalesPeriodChartItem(
      periodLabel: json['period_label'] ?? '',
      sales: double.tryParse((json['sales'] ?? 0).toString()) ?? 0.0,
      expenses: double.tryParse((json['expenses'] ?? 0).toString()) ?? 0.0,
    );
  }
}
