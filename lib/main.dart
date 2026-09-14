import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storage_lens/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    // ProviderScope stores the state of all providers.
    const ProviderScope(
      child: App(),
    ),
  );
}
