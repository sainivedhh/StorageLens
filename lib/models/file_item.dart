import 'package:path/path.dart' as p;
import 'package:storage_lens/models/file_category.dart';

/// An immutable representation of a single file found during a storage scan.
///
/// [FileItem] is a plain Dart data class with no Flutter dependencies,
/// making it trivially unit-testable and serializable to/from SQLite.
class FileItem {
  /// Creates a [FileItem].
  ///
  /// All fields are required. Prefer the [FileItem.fromPath] factory
  /// when creating instances from a real filesystem path.
  const FileItem({
    required this.id,
    required this.path,
    required this.sizeBytes,
    required this.modifiedAt,
    required this.category,
  });

  /// The SQLite row id (0 for unsaved items).
  final int id;

  /// Absolute filesystem path to the file.
  final String path;

  /// File size in bytes.
  final int sizeBytes;

  /// Last-modified timestamp.
  final DateTime modifiedAt;

  /// The [FileCategory] this file belongs to, derived from its extension.
  final FileCategory category;

  // ---------------------------------------------------------------------------
  // Computed properties
  // ---------------------------------------------------------------------------

  /// The file's base name (including extension), e.g. `photo.jpg`.
  String get name => p.basename(path);

  /// The file's extension without the leading dot, e.g. `jpg`.
  /// Returns an empty string for files with no extension.
  String get extension => p.extension(path).replaceFirst('.', '');

  /// The parent directory path.
  String get directory => p.dirname(path);

  // ---------------------------------------------------------------------------
  // Factory constructors
  // ---------------------------------------------------------------------------

  /// Creates a [FileItem] by inspecting [path], [sizeBytes], and [modifiedAt].
  ///
  /// The [category] is automatically derived from the file extension.
  /// [id] defaults to 0 (not yet persisted to the database).
  factory FileItem.fromPath({
    required String path,
    required int sizeBytes,
    required DateTime modifiedAt,
    int id = 0,
  }) {
    final ext = p.extension(path).replaceFirst('.', '');
    return FileItem(
      id: id,
      path: path,
      sizeBytes: sizeBytes,
      modifiedAt: modifiedAt,
      category: FileCategory.fromExtension(ext),
    );
  }

  // ---------------------------------------------------------------------------
  // SQLite serialization
  // ---------------------------------------------------------------------------

  /// Converts this [FileItem] to a map suitable for SQLite insertion.
  ///
  /// The [runId] ties this item to a specific scan run in the database.
  Map<String, dynamic> toMap({required int runId}) {
    return {
      'run_id': runId,
      'path': path,
      'size_bytes': sizeBytes,
      'modified_at': modifiedAt.millisecondsSinceEpoch,
      'category': category.name,
    };
  }

  /// Creates a [FileItem] from a SQLite row [map].
  factory FileItem.fromMap(Map<String, dynamic> map) {
    return FileItem(
      id: map['id'] as int,
      path: map['path'] as String,
      sizeBytes: map['size_bytes'] as int,
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(
        map['modified_at'] as int,
      ),
      category: FileCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => FileCategory.other,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Value equality and debugging
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileItem &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          sizeBytes == other.sizeBytes &&
          modifiedAt == other.modifiedAt &&
          category == other.category;

  @override
  int get hashCode =>
      path.hashCode ^ sizeBytes.hashCode ^ modifiedAt.hashCode ^ category.hashCode;

  @override
  String toString() =>
      'FileItem(name: $name, size: $sizeBytes, category: ${category.name})';

  /// Returns a copy of this [FileItem] with the given fields replaced.
  FileItem copyWith({
    int? id,
    String? path,
    int? sizeBytes,
    DateTime? modifiedAt,
    FileCategory? category,
  }) {
    return FileItem(
      id: id ?? this.id,
      path: path ?? this.path,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      category: category ?? this.category,
    );
  }
}
