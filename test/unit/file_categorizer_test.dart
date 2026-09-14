import 'package:flutter_test/flutter_test.dart';
import 'package:storage_lens/models/file_category.dart';
import 'package:storage_lens/models/file_item.dart';

void main() {
  group('FileCategory extension classification', () {
    test('Correctly classifies image extensions (case-insensitive)', () {
      expect(FileCategory.fromExtension('jpg'), FileCategory.images);
      expect(FileCategory.fromExtension('PNG'), FileCategory.images);
      expect(FileCategory.fromExtension(' JpeG '), FileCategory.images);
      expect(FileCategory.fromExtension('heic'), FileCategory.images);
    });

    test('Correctly classifies video extensions', () {
      expect(FileCategory.fromExtension('mp4'), FileCategory.videos);
      expect(FileCategory.fromExtension('mkv'), FileCategory.videos);
      expect(FileCategory.fromExtension('MOV'), FileCategory.videos);
    });

    test('Correctly classifies document extensions', () {
      expect(FileCategory.fromExtension('pdf'), FileCategory.documents);
      expect(FileCategory.fromExtension('DOCX'), FileCategory.documents);
      expect(FileCategory.fromExtension('txt'), FileCategory.documents);
      expect(FileCategory.fromExtension('json'), FileCategory.documents);
    });

    test('Correctly classifies audio extensions', () {
      expect(FileCategory.fromExtension('mp3'), FileCategory.audio);
      expect(FileCategory.fromExtension('wav'), FileCategory.audio);
      expect(FileCategory.fromExtension('FLAC'), FileCategory.audio);
    });

    test('Classifies unknown or empty extensions as other', () {
      expect(FileCategory.fromExtension('xyz'), FileCategory.other);
      expect(FileCategory.fromExtension('unknown'), FileCategory.other);
      expect(FileCategory.fromExtension(''), FileCategory.other);
      expect(FileCategory.fromExtension('   '), FileCategory.other);
    });
  });

  group('FileItem.fromPath', () {
    test('Automatically assigns category based on file extension in path', () {
      final imageItem = FileItem.fromPath(
        path: '/storage/emulated/0/DCIM/Camera/IMG_20240101.jpg',
        sizeBytes: 1024,
        modifiedAt: DateTime.now(),
      );
      expect(imageItem.category, FileCategory.images);
      expect(imageItem.name, 'IMG_20240101.jpg');
      expect(imageItem.extension, 'jpg');
      expect(imageItem.directory, '/storage/emulated/0/DCIM/Camera');

      final unknownItem = FileItem.fromPath(
        path: '/storage/emulated/0/Download/some_file',
        sizeBytes: 1024,
        modifiedAt: DateTime.now(),
      );
      expect(unknownItem.category, FileCategory.other);
      expect(unknownItem.name, 'some_file');
      expect(unknownItem.extension, '');
    });
  });
}
