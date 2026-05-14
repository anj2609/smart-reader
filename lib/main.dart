import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

/// Application entry point.
///
/// Wraps the entire widget tree in a [ProviderScope] so that
/// Riverpod providers are available throughout the app.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: App()));
}
