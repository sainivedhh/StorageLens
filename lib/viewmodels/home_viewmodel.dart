import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:storage_lens/models/storage_summary.dart';
import 'package:storage_lens/services/android_storage_service.dart';
import 'package:storage_lens/services/database_service.dart';
import 'package:storage_lens/services/storage_service.dart';
import 'package:storage_lens/services/windows_storage_service.dart';

part 'home_viewmodel.g.dart';

// -----------------------------------------------------------------------------
// Providers for Services
// -----------------------------------------------------------------------------

@Riverpod(keepAlive: true)
DatabaseService databaseService(DatabaseServiceRef ref) {
  return DatabaseService();
}

@Riverpod(keepAlive: true)
StorageService storageService(StorageServiceRef ref) {
  if (Platform.isWindows) {
    return WindowsStorageService();
  } else if (Platform.isAndroid) {
    return AndroidStorageService();
  } else {
    // Fallback stub for unsupported platforms.
    return WindowsStorageService(); 
  }
}

// -----------------------------------------------------------------------------
// Home ViewModel
// -----------------------------------------------------------------------------

/// Manages the state for the Home Screen.
///
/// This ViewModel is responsible for initializing the database, loading the
/// cached storage summary on startup, and triggering new scans.
@riverpod
class HomeViewModel extends _$HomeViewModel {
  @override
  FutureOr<StorageSummary> build() async {
    final db = ref.watch(databaseServiceProvider);
    
    // 1. Initialize the database (safe to call multiple times)
    await db.init();

    // 2. Try to load the latest scan from the cache
    final cachedSummary = await db.loadLatestScan();

    if (cachedSummary != null) {
      return cachedSummary;
    }

    // 3. If no cache exists, return an empty summary.
    // The UI will likely show a "Scan Now" button in this case.
    return StorageSummary.empty;
  }

  /// Initiates a new file system scan.
  Future<void> rescan() async {
    state = const AsyncValue.loading();
    
    try {
      final storage = ref.read(storageServiceProvider);
      final db = ref.read(databaseServiceProvider);

      // 1. Request permissions
      final hasPermission = await storage.requestPermissions();
      if (!hasPermission) {
        state = AsyncValue.error('Storage permission denied', StackTrace.current);
        return;
      }

      // 2. Prepare database for new scan
      final runId = await db.startNewScan();
      
      final List<FileItem> allFiles = [];
      final List<FileItem> batch = [];
      const batchSize = 500;

      // 3. Scan storage and batch insert to database
      await for (final file in storage.scanStorage()) {
        allFiles.add(file);
        batch.add(file);

        if (batch.length >= batchSize) {
          await db.insertFilesBatch(runId, batch);
          batch.clear();
        }
      }

      // Insert any remaining files
      if (batch.isNotEmpty) {
        await db.insertFilesBatch(runId, batch);
      }

      // 4. Cleanup old scans
      await db.clearOldScans(runId);

      // 5. Update state with new summary
      final summary = StorageSummary.fromItems(allFiles);
      state = AsyncValue.data(summary);

    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
