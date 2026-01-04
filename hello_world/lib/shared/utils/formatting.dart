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

  /// Formats a number to currency string (e.g. "1,250.00").
  static String formatCurrency(num amount) {
    // Round to 2 decimals for calculations, but show 0 if it's a whole number
    String s = amount % 1 == 0 ? amount.toInt().toString() : amount.toStringAsFixed(2);
    
    List<String> parts = s.split('.');
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    parts[0] = parts[0].replaceAllMapped(reg, (Match match) => '${match[1]},');
    
    return parts.length > 1 ? "${parts[0]}.${parts[1]}" : parts[0];
  }
}
