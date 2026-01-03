class Formatter {
  /// Parses a string like "1,250" or "Rs 1,250" to a double.
  /// Returns 0.0 if parsing fails.
  static double parseDouble(String input) {
    if (input.isEmpty) return 0.0;

    // Remove "Rs", commas, spaces, and other non-numeric chars (except decimal point)
    String cleanString = input.replaceAll(RegExp(r'[^\d.]'), '');

    return double.tryParse(cleanString) ?? 0.0;
  }

  /// Parses a string to int.
  static int parseInt(String input) {
    if (input.isEmpty) return 0;
     String cleanString = input.replaceAll(RegExp(r'[^\d]'), '');
     return int.tryParse(cleanString) ?? 0;
  }

  /// Formats a number to currency string (e.g. "1,250").
  static String formatCurrency(num amount) {
    // Simple implementation for comma separation
    String s = amount.toString();
    if (s.contains('.')) {
       List<String> parts = s.split('.');
       s = parts[0];
       // We can ignore decimal part for simple display or append it
       // Let's keep it integer-like for now as per app style, or 2 decimals
    }

    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    // Fix: Pass the function directly to satisfy type system
    return s.replaceAllMapped(reg, (Match match) => '${match[1]},');
  }
}
