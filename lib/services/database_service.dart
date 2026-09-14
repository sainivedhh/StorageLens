import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:storage_lens/models/file_category.dart';
import 'package:storage_lens/models/file_item.dart';
import 'package:storage_lens/models/storage_summary.dart';

/// Handles SQLite database initialization, schema creation, and CRUD operations.
///
/// We cache scan results locally so the app starts instantly and doesn't
/// need to re-scan the entire filesystem (which can be slow) every time
/// it opens.
class DatabaseService {
  Database? _db;

  /// Initializes the SQLite database. Must be called before any other operations.
  Future<void> init() async {
    if (_db != null) return;

    // Use FFI for Desktop platforms (Windows, Linux, macOS).
    // Standard sqflite handles Android and iOS natively.
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = p.join(await getDatabasesPath(), 'storagelens_cache.db');

    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        // Table recording each scan run.
        await db.execute('''
          CREATE TABLE scan_runs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            scanned_at INTEGER NOT NULL
          )
        ''');

        // Table storing every file found during a scan.
        await db.execute('''
          CREATE TABLE file_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            run_id INTEGER NOT NULL,
            path TEXT NOT NULL,
            size_bytes INTEGER NOT NULL,
            modified_at INTEGER NOT NULL,
            category TEXT NOT NULL,
            FOREIGN KEY (run_id) REFERENCES scan_runs (id) ON DELETE CASCADE
          )
        ''');

        // Indexes for faster querying
        await db.execute('CREATE INDEX idx_file_category ON file_items (category)');
        await db.execute('CREATE INDEX idx_file_run_id ON file_items (run_id)');
      },
    );
  }

  Database get db {
    if (_db == null) {
      throw StateError('DatabaseService.init() must be called first.');
    }
    return _db!;
  }

  /// Begins a new scan run and returns its ID.
  Future<int> startNewScan() async {
    return await db.insert('scan_runs', {
      'scanned_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Inserts a batch of files associated with a [runId].
  Future<void> insertFilesBatch(int runId, List<FileItem> files) async {
    if (files.isEmpty) return;

    final batch = db.batch();
    for (final file in files) {
      batch.insert('file_items', file.toMap(runId: runId));
    }
    await batch.commit(noResult: true);
  }

  /// Clears older scan runs, keeping only the latest one.
  Future<void> clearOldScans(int currentRunId) async {
    await db.delete(
      'scan_runs',
      where: 'id != ?',
      whereArgs: [currentRunId],
    );
    // ON DELETE CASCADE on file_items handles cleaning up associated files.
  }

  /// Loads the summary and all files from the most recent scan run.
  /// Returns null if no previous scan exists.
  Future<StorageSummary?> loadLatestScan() async {
    // 1. Find the latest run
    final runs = await db.query(
      'scan_runs',
      orderBy: 'scanned_at DESC',
      limit: 1,
    );

    if (runs.isEmpty) return null;

    final latestRun = runs.first;
    final runId = latestRun['id'] as int;
    final scannedAt = DateTime.fromMillisecondsSinceEpoch(latestRun['scanned_at'] as int);

    // 2. Load all files for this run
    final fileMaps = await db.query(
      'file_items',
      where: 'run_id = ?',
      whereArgs: [runId],
    );

    final items = fileMaps.map((map) => FileItem.fromMap(map)).toList();

    return StorageSummary.fromItems(items, scannedAt: scannedAt);
  }

  /// Removes a specific file from the database cache.
  Future<void> removeFile(int id) async {
    await db.delete(
      'file_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
