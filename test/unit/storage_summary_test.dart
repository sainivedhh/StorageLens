import 'package:flutter_test/flutter_test.dart';
import 'package:storage_lens/models/file_category.dart';
import 'package:storage_lens/models/file_item.dart';
import 'package:storage_lens/models/storage_summary.dart';

void main() {
  group('StorageSummary aggregation', () {
    test('fromItems correctly aggregates bytes and groups files', () {
      final now = DateTime.now();
      
      final items = [
        FileItem.fromPath(path: '1.jpg', sizeBytes: 100, modifiedAt: now),
        FileItem.fromPath(path: '2.png', sizeBytes: 200, modifiedAt: now),
        FileItem.fromPath(path: '1.mp4', sizeBytes: 1000, modifiedAt: now),
        FileItem.fromPath(path: '1.pdf', sizeBytes: 50, modifiedAt: now),
        FileItem.fromPath(path: '1.unknown', sizeBytes: 10, modifiedAt: now),
        FileItem.fromPath(path: '2.unknown', sizeBytes: 20, modifiedAt: now),
      ];

      final summary = StorageSummary.fromItems(items);

      expect(summary.totalBytes, 1380);
      expect(summary.totalFiles, 6);

      // Check byte sums per category
      expect(summary.bytesPerCategory[FileCategory.images], 300);
      expect(summary.bytesPerCategory[FileCategory.videos], 1000);
      expect(summary.bytesPerCategory[FileCategory.documents], 50);
      expect(summary.bytesPerCategory[FileCategory.audio], 0);
      expect(summary.bytesPerCategory[FileCategory.other], 30);

      // Check file lists per category
      expect(summary.filesPerCategory[FileCategory.images]?.length, 2);
      expect(summary.filesPerCategory[FileCategory.videos]?.length, 1);
      expect(summary.filesPerCategory[FileCategory.audio]?.length, 0);

      // Check fraction calculation
      expect(summary.fractionForCategory(FileCategory.images), 300 / 1380);
      expect(summary.fractionForCategory(FileCategory.audio), 0.0);
    });

    test('filesForCategory sorts correctly based on mode', () {
      final date1 = DateTime(2024, 1, 1);
      final date2 = DateTime(2024, 1, 2);
      final date3 = DateTime(2024, 1, 3);

      final items = [
        FileItem.fromPath(path: 'small_new.jpg', sizeBytes: 10, modifiedAt: date3),
        FileItem.fromPath(path: 'large_old.jpg', sizeBytes: 100, modifiedAt: date1),
        FileItem.fromPath(path: 'medium_mid.jpg', sizeBytes: 50, modifiedAt: date2),
      ];

      final summary = StorageSummary.fromItems(items);

      // Test size sort (largest first)
      final bySize = summary.filesForCategory(FileCategory.images, mode: SortMode.bySize);
      expect(bySize[0].name, 'large_old.jpg');
      expect(bySize[1].name, 'medium_mid.jpg');
      expect(bySize[2].name, 'small_new.jpg');

      // Test date sort (newest first)
      final byDate = summary.filesForCategory(FileCategory.images, mode: SortMode.byDate);
      expect(byDate[0].name, 'small_new.jpg');
      expect(byDate[1].name, 'medium_mid.jpg');
      expect(byDate[2].name, 'large_old.jpg');
    });

    test('fractionForCategory handles zero total bytes safely', () {
      final summary = StorageSummary.empty;
      expect(summary.fractionForCategory(FileCategory.images), 0.0);
      expect(summary.totalBytes, 0);
    });
  });
}
