import 'package:storage_lens/models/file_category.dart';
import 'package:storage_lens/models/file_item.dart';

/// An aggregated, read-only summary of a completed storage scan.
///
/// [StorageSummary] is computed from a flat list of [FileItem]s and exposes
/// the per-category breakdowns needed by the home screen chart and cards.
/// Being a pure data class, it is fully unit-testable without any Flutter
/// widget context.
class StorageSummary {
  /// Creates a [StorageSummary] directly from pre-computed values.
  ///
  /// In most cases, prefer [StorageSummary.fromItems] to build this from a
  /// raw list of scanned files.
  const StorageSummary({
    required this.totalBytes,
    required this.bytesPerCategory,
    required this.filesPerCategory,
    required this.scannedAt,
  });

  /// Total storage used by all scanned files, in bytes.
  final int totalBytes;

  /// Bytes consumed by each [FileCategory].
  final Map<FileCategory, int> bytesPerCategory;

  /// Files grouped by [FileCategory], each list sorted by size descending.
  final Map<FileCategory, List<FileItem>> filesPerCategory;

  /// When this summary was produced (i.e., the scan completion time).
  final DateTime scannedAt;

  // ---------------------------------------------------------------------------
  // Factory
  // ---------------------------------------------------------------------------

  /// Builds a [StorageSummary] by aggregating a flat list of [FileItem]s.
  ///
  /// The [scannedAt] parameter defaults to [DateTime.now()] if not provided.
  ///
  /// Complexity: O(n) in the number of items.
  factory StorageSummary.fromItems(
    List<FileItem> items, {
    DateTime? scannedAt,
  }) {
    final bytesPerCategory = <FileCategory, int>{};
    final filesPerCategory = <FileCategory, List<FileItem>>{};

    // Initialise all categories so callers never get a null/missing key.
    for (final cat in FileCategory.values) {
      bytesPerCategory[cat] = 0;
      filesPerCategory[cat] = [];
    }

    var totalBytes = 0;

    for (final item in items) {
      totalBytes += item.sizeBytes;
      bytesPerCategory[item.category] =
          (bytesPerCategory[item.category] ?? 0) + item.sizeBytes;
      filesPerCategory[item.category]!.add(item);
    }

    // Sort each category's file list by size, largest first.
    for (final list in filesPerCategory.values) {
      list.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    }

    return StorageSummary(
      totalBytes: totalBytes,
      bytesPerCategory: bytesPerCategory,
      filesPerCategory: filesPerCategory,
      scannedAt: scannedAt ?? DateTime.now(),
    );
  }

  /// An empty summary used as a placeholder before the first scan.
  static final empty = StorageSummary(
    totalBytes: 0,
    bytesPerCategory: {for (final c in FileCategory.values) c: 0},
    filesPerCategory: {for (final c in FileCategory.values) c: <FileItem>[]},
    scannedAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  // ---------------------------------------------------------------------------
  // Computed helpers
  // ---------------------------------------------------------------------------

  /// Total number of scanned files across all categories.
  int get totalFiles =>
      filesPerCategory.values.fold(0, (sum, list) => sum + list.length);

  /// Returns the fraction (0.0–1.0) of total storage used by [category].
  ///
  /// Returns 0.0 if [totalBytes] is zero (prevents division by zero).
  double fractionForCategory(FileCategory category) {
    if (totalBytes == 0) return 0;
    return (bytesPerCategory[category] ?? 0) / totalBytes;
  }

  /// Returns all files for [category] sorted according to [mode].
  List<FileItem> filesForCategory(
    FileCategory category, {
    SortMode mode = SortMode.bySize,
  }) {
    final list = List<FileItem>.from(filesPerCategory[category] ?? []);
    switch (mode) {
      case SortMode.bySize:
        list.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
      case SortMode.byDate:
        list.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    }
    return list;
  }

  @override
  String toString() =>
      'StorageSummary(total: ${totalBytes}B, files: $totalFiles, '
      'scannedAt: $scannedAt)';
}

/// Determines the order in which files are listed on the [FileListScreen].
enum SortMode {
  /// Sort by file size, largest first.
  bySize,

  /// Sort by last-modified date, most recent first.
  byDate,
}
