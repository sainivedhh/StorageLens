import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storage_lens/models/file_category.dart';
import 'package:storage_lens/models/file_item.dart';
import 'package:storage_lens/models/storage_summary.dart';
import 'package:storage_lens/screens/home_screen.dart';
import 'package:storage_lens/viewmodels/home_viewmodel.dart';
import 'package:storage_lens/widgets/category_card.dart';
import 'package:storage_lens/widgets/scan_progress_indicator.dart';
import 'package:storage_lens/widgets/storage_pie_chart.dart';
import 'package:storage_lens/services/database_service.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  testWidgets('HomeScreen shows progress indicator when loading', (WidgetTester tester) async {
    final mockDb = MockDatabaseService();
    // To simulate loading indefinitely, we can make loadLatestScan return a never-completing future.
    when(() => mockDb.init()).thenAnswer((_) async {});
    when(() => mockDb.loadLatestScan()).thenAnswer((_) => Completer<StorageSummary?>().future);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseServiceProvider.overrideWithValue(mockDb),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    expect(find.byType(ScanProgressIndicator), findsOneWidget);
    expect(find.text('Scanning storage...'), findsOneWidget);
  });

  testWidgets('HomeScreen renders pie chart and category cards with data', (WidgetTester tester) async {
    final mockSummary = StorageSummary.fromItems([
      FileItem.fromPath(path: '1.jpg', sizeBytes: 100, modifiedAt: DateTime.now()),
      FileItem.fromPath(path: '2.mp4', sizeBytes: 200, modifiedAt: DateTime.now()),
    ]);
    
    final mockDb = MockDatabaseService();
    when(() => mockDb.init()).thenAnswer((_) async {});
    when(() => mockDb.loadLatestScan()).thenAnswer((_) async => mockSummary);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseServiceProvider.overrideWithValue(mockDb),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    // Give the widget time to render its AsyncData state
    await tester.pumpAndSettle();

    // Verify Pie Chart is present
    expect(find.byType(StoragePieChart), findsOneWidget);

    // Verify all 5 category cards are rendered (even empty ones)
    expect(find.byType(CategoryCard), findsNWidgets(5));

    // Verify specific text is rendered for the data we provided
    expect(find.text('Images'), findsOneWidget);
    expect(find.text('Videos'), findsOneWidget);
    
    // Total used should be 300 B
    expect(find.text('Total Used: 300.00 B'), findsOneWidget);
  });
}
