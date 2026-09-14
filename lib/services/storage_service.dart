import 'package:storage_lens/models/file_item.dart';

/// The contract that all platform-specific storage implementations must fulfil.
///
/// ## Design rationale
/// Abstracting storage access behind this interface decouples the business
/// logic (ViewModels, tests) from platform APIs. To add Windows support, you
/// implement [StorageService] in a new class and register it at startup —
/// zero changes to the ViewModel or UI layers.
///
/// ## Current implementations
/// - [AndroidStorageService] — uses `permission_handler` + `dart:io`.
/// - [WindowsStorageService] — documented stub, ready for extension.
abstract class StorageService {
  /// Requests the necessary platform permissions to read storage.
  ///
  /// Returns `true` if all required permissions were granted, `false`
  /// otherwise (e.g. the user denied the request). On platforms that do not
  /// require explicit permission (e.g. Windows Desktop), this should return
  /// `true` immediately.
  Future<bool> requestPermissions();

  /// Emits one [FileItem] for every file found during a storage scan.
  ///
  /// The stream completes when the scan finishes. Callers should handle
  /// errors emitted by the stream (e.g. permission denied mid-scan).
  ///
  /// The stream may emit items concurrently from different directories; do
  /// not assume any ordering in the emitted items.
  Stream<FileItem> scanStorage();

  /// Permanently deletes the file at [path] from the device.
  ///
  /// Throws a [StorageServiceException] if the file cannot be deleted
  /// (e.g. it does not exist, or deletion is denied by the OS).
  Future<void> deleteFile(String path);
}

/// Thrown by [StorageService] implementations when a storage operation fails.
class StorageServiceException implements Exception {
  /// Creates a [StorageServiceException] with a human-readable [message].
  const StorageServiceException(this.message, {this.cause});

  /// A human-readable description of the failure.
  final String message;

  /// The underlying exception that caused this failure, if any.
  final Object? cause;

  @override
  String toString() => 'StorageServiceException: $message'
      '${cause != null ? ' (caused by: $cause)' : ''}';
}
