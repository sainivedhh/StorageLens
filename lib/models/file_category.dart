import 'package:flutter/material.dart';

/// Represents the high-level category that a file belongs to.
///
/// Each category carries display metadata (label, icon, color) so that UI
/// widgets never need to hardcode category-specific strings or colors.
enum FileCategory {
  /// Image files (.jpg, .png, .gif, .webp, .bmp, .heic, etc.)
  images,

  /// Video files (.mp4, .mov, .avi, .mkv, .webm, etc.)
  videos,

  /// Document files (.pdf, .docx, .xlsx, .pptx, .txt, .csv, etc.)
  documents,

  /// Audio files (.mp3, .aac, .wav, .flac, .ogg, .m4a, etc.)
  audio,

  /// Any file that does not match the above categories.
  other;

  // ---------------------------------------------------------------------------
  // Display metadata
  // ---------------------------------------------------------------------------

  /// Human-readable label shown in the UI.
  String get label {
    switch (this) {
      case FileCategory.images:
        return 'Images';
      case FileCategory.videos:
        return 'Videos';
      case FileCategory.documents:
        return 'Documents';
      case FileCategory.audio:
        return 'Audio';
      case FileCategory.other:
        return 'Other';
    }
  }

  /// Icon representing this category.
  IconData get icon {
    switch (this) {
      case FileCategory.images:
        return Icons.image_rounded;
      case FileCategory.videos:
        return Icons.videocam_rounded;
      case FileCategory.documents:
        return Icons.description_rounded;
      case FileCategory.audio:
        return Icons.music_note_rounded;
      case FileCategory.other:
        return Icons.folder_rounded;
    }
  }

  /// Brand color for this category used in charts and cards.
  Color get color {
    switch (this) {
      case FileCategory.images:
        return const Color(0xFF7C6AF7); // violet
      case FileCategory.videos:
        return const Color(0xFFE8637A); // rose
      case FileCategory.documents:
        return const Color(0xFF48C1B5); // teal
      case FileCategory.audio:
        return const Color(0xFFF59E42); // amber
      case FileCategory.other:
        return const Color(0xFF6B7280); // grey
    }
  }

  // ---------------------------------------------------------------------------
  // Extension-based classification
  // ---------------------------------------------------------------------------

  /// Set of lowercase file extensions that map to [FileCategory.images].
  static const _imageExts = {
    'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic', 'heif',
    'tiff', 'tif', 'svg', 'ico', 'raw', 'cr2', 'nef', 'arw',
  };

  /// Set of lowercase file extensions that map to [FileCategory.videos].
  static const _videoExts = {
    'mp4', 'mov', 'avi', 'mkv', 'webm', 'flv', 'wmv', 'm4v',
    '3gp', 'ts', 'mts', 'm2ts', 'vob', 'ogv',
  };

  /// Set of lowercase file extensions that map to [FileCategory.documents].
  static const _documentExts = {
    'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
    'txt', 'csv', 'rtf', 'odt', 'ods', 'odp', 'epub',
    'md', 'json', 'xml', 'html', 'htm', 'log',
  };

  /// Set of lowercase file extensions that map to [FileCategory.audio].
  static const _audioExts = {
    'mp3', 'aac', 'wav', 'flac', 'ogg', 'm4a', 'wma',
    'opus', 'aiff', 'aif', 'amr', 'mid', 'midi',
  };

  /// Returns the [FileCategory] for a given file [extension].
  ///
  /// The [extension] should NOT include the leading dot. Comparison is
  /// case-insensitive. Returns [FileCategory.other] for unknown extensions.
  ///
  /// Example:
  /// ```dart
  /// FileCategory.fromExtension('jpg')  // → FileCategory.images
  /// FileCategory.fromExtension('PDF')  // → FileCategory.documents
  /// FileCategory.fromExtension('xyz')  // → FileCategory.other
  /// FileCategory.fromExtension('')     // → FileCategory.other
  /// ```
  static FileCategory fromExtension(String extension) {
    final ext = extension.toLowerCase().trim();
    if (_imageExts.contains(ext)) return FileCategory.images;
    if (_videoExts.contains(ext)) return FileCategory.videos;
    if (_documentExts.contains(ext)) return FileCategory.documents;
    if (_audioExts.contains(ext)) return FileCategory.audio;
    return FileCategory.other;
  }
}
