import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:storage_lens/models/file_item.dart';
import 'package:storage_lens/services/storage_service.dart';

/// Android implementation of [StorageService] using `dart:io`.
///
/// This service traverses the external storage directory recursively.
/// It uses `permission_handler` to request the appropriate permissions
/// depending on the Android API level.
class AndroidStorageService implements StorageService {
  @override
  Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) return false;

    final androidInfo = await DeviceInfoPlugin().androidInfo;

    // We decided to request MANAGE_EXTERNAL_STORAGE for a full scan,
    // which applies to Android 11+ (API 30+).
    if (androidInfo.version.sdkInt >= 30) {
      final status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    } else {
      // For older Android versions, READ_EXTERNAL_STORAGE is sufficient.
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  }

  @override
  Stream<FileItem> scanStorage() async* {
    try {
      // Get the primary external storage directory (e.g. /storage/emulated/0)
      final directory = await getExternalStorageDirectory();
      
      // getExternalStorageDirectory often returns app-specific paths like
      // /storage/emulated/0/Android/data/com.storagelens/files.
      // We want to scan the root of external storage.
      // A common workaround is to parse the path.
      if (directory == null) {
        throw const StorageServiceException('Could not determine external storage path.');
      }
      
      final pathParts = directory.path.split('/');
      final int emulatedIndex = pathParts.indexOf('emulated');
      String rootPath = directory.path;
      
      if (emulatedIndex != -1 && pathParts.length > emulatedIndex + 1) {
        rootPath = pathParts.sublist(0, emulatedIndex + 2).join('/');
      } else {
        // Fallback if parsing fails.
        rootPath = '/storage/emulated/0';
      }

      final rootDir = Directory(rootPath);
      
      if (!await rootDir.exists()) {
        throw const StorageServiceException('Root directory does not exist.');
      }

      // Recursively list all files.
      // Note: We skip hidden directories (starting with '.') to avoid
      // scanning excessive system/cache files.
      yield* _scanDirectoryRecursive(rootDir);

    } on FileSystemException catch (e) {
      throw StorageServiceException('File system error during scan.', cause: e);
    } catch (e) {
      throw StorageServiceException('Unknown error during scan.', cause: e);
    }
  }

  Stream<FileItem> _scanDirectoryRecursive(Directory dir) async* {
    try {
      final entities = dir.list(recursive: false, followLinks: false);
      await for (final entity in entities) {
        final name = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty, orElse: () => '');
        
        // Skip hidden files/directories (e.g. .thumbnails, .android)
        if (name.startsWith('.')) continue;
        
        if (entity is File) {
          try {
            final stat = await entity.stat();
            yield FileItem.fromPath(
              path: entity.path,
              sizeBytes: stat.size,
              modifiedAt: stat.modified,
            );
          } catch (e) {
            // Ignore files we cannot stat (e.g. permission denied on specific files)
          }
        } else if (entity is Directory) {
          yield* _scanDirectoryRecursive(entity);
        }
      }
    } catch (e) {
      // Ignore errors when listing specific directories (e.g. permission denied)
    }
  }

  @override
  Future<void> deleteFile(String path) async {
    final file = File(path);
    try {
      if (await file.exists()) {
        await file.delete();
      } else {
        throw const StorageServiceException('File not found.');
      }
    } on FileSystemException catch (e) {
       throw StorageServiceException('Failed to delete file.', cause: e);
    }
  }
}
