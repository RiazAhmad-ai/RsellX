import 'package:uuid/uuid.dart';

/// Centralized ID generation utility
/// Uses UUID v4 for globally unique IDs
class IdGenerator {
  static const Uuid _uuid = Uuid();

  /// Generates a unique ID using UUID v4
  /// Format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
  static String generate() {
    return _uuid.v4();
  }

  /// Generates a short ID (first 8 characters of UUID)
  /// Use when full UUID is not necessary
  static String generateShort() {
    return _uuid.v4().substring(0, 8);
  }

  /// Generates a numeric-only ID based on timestamp and random
  /// Use for barcode/SKU generation
  static String generateNumeric() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Generates a prefixed ID (e.g., EXP-xxxxxxxx for expenses)
  static String generateWithPrefix(String prefix) {
    return '$prefix-${_uuid.v4().substring(0, 8)}';
  }

  /// Alias for generateWithPrefix for backward compatibility/preferred naming
  static String generateId(String prefix) => generateWithPrefix(prefix);
}
