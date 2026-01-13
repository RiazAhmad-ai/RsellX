// lib/data/repositories/data_store.dart
import 'package:flutter/foundation.dart';

/// Legacy DataStore - replaced by specialized providers in lib/providers/
/// This class is kept temporarily to avoid build errors during transition.
class DataStore extends ChangeNotifier {
  static final DataStore _instance = DataStore._internal();
  factory DataStore() => _instance;
  DataStore._internal();
}
