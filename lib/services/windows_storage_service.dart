import 'package:storage_lens/models/file_item.dart';
import 'package:storage_lens/services/storage_service.dart';

/// A stub implementation of [StorageService] for Windows desktop.
///
/// This demonstrates how the StorageService abstraction allows the application
/// to support multiple platforms cleanly without polluting the view models
/// with platform-specific code.
///
/// In a full implementation, this class would use `dart:io` to recursively
/// scan the `C:\Users\<username>` directory.
class WindowsStorageService implements StorageService {
  @override
  Future<bool> requestPermissions() async {
    // Windows desktop typically does not require explicit runtime permissions
    // to read user directories in the same way Android does.
    return true;
  }

  @override
  Stream<FileItem> scanStorage() async* {
    // Stub implementation: returns an empty stream immediately.
    // A real implementation would yield FileItems here.
    // e.g. await for (final entity in Directory('C:\\Users').list(recursive: true)) { ... }
    yield* const Stream<FileItem>.empty();
  }

  @override
  Future<void> deleteFile(String path) async {
    // Stub implementation.
    // A real implementation would:
    // final file = File(path);
    // if (await file.exists()) {
    //   await file.delete();
    // } else {
    //   throw StorageServiceException('File not found', cause: null);
    // }
    throw const StorageServiceException(
      'File deletion is not supported in the Windows stub implementation.',
    );
  }
}
