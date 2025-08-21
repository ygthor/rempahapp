import 'package:kanesanapp/models/debt_item.dart';

class CustomerDebt {
  final String customerCode;
  final String outletsCode;
  final String companyName;
  final List<DebtItem> debtItems;

  CustomerDebt({
    required this.customerCode,
    required this.outletsCode,
    required this.companyName,
    required this.debtItems,
  });

  double get totalOutstandingAmount {
    return debtItems.fold(0.0, (sum, item) => sum + item.outstandingAmount);
  }
}
