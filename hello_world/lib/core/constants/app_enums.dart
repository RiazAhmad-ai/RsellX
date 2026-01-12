/// Centralized enums for the application
/// Use these instead of hardcoded strings

/// Status of a sale record
enum SaleStatus {
  sold('Sold'),
  refunded('Refunded');

  final String value;
  const SaleStatus(this.value);

  static SaleStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'refunded':
        return SaleStatus.refunded;
      case 'sold':
      default:
        return SaleStatus.sold;
    }
  }

  @override
  String toString() => value;
}

/// Type of credit record
enum CreditType {
  lend('Lend'),   // Main udhaar diya (Receivables)
  borrow('Borrow'); // Maine udhaar liya (Payables)

  final String value;
  const CreditType(this.value);

  static CreditType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'borrow':
        return CreditType.borrow;
      case 'lend':
      default:
        return CreditType.lend;
    }
  }

  @override
  String toString() => value;
}

/// Expense categories
enum ExpenseCategory {
  food('Food'),
  bills('Bills'),
  rent('Rent'),
  travel('Travel'),
  extra('Extra'),
  general('General');

  final String value;
  const ExpenseCategory(this.value);

  static ExpenseCategory fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'food':
        return ExpenseCategory.food;
      case 'bills':
        return ExpenseCategory.bills;
      case 'rent':
        return ExpenseCategory.rent;
      case 'travel':
        return ExpenseCategory.travel;
      case 'extra':
        return ExpenseCategory.extra;
      default:
        return ExpenseCategory.general;
    }
  }

  static List<String> get displayValues => [
    food.value,
    bills.value,
    rent.value,
    travel.value,
    extra.value,
  ];

  @override
  String toString() => value;
}

/// Analytics filter type
enum AnalyticsFilter {
  weekly('Weekly'),
  monthly('Monthly'),
  annual('Annual');

  final String value;
  const AnalyticsFilter(this.value);

  @override
  String toString() => value;
}
