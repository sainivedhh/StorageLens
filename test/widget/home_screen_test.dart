import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage_lens/models/file_category.dart';
import 'package:storage_lens/models/file_item.dart';
import 'package:storage_lens/models/storage_summary.dart';
import 'package:storage_lens/screens/home_screen.dart';
import 'package:storage_lens/viewmodels/home_viewmodel.dart';
import 'package:storage_lens/widgets/category_card.dart';
import 'package:storage_lens/widgets/scan_progress_indicator.dart';
import 'package:storage_lens/widgets/storage_pie_chart.dart';

void main() {
  testWidgets('HomeScreen shows progress indicator when loading', (WidgetTester tester) async {
    // Create a mock view model that stays in the loading state.
    // In Riverpod 2.0+, we can just override the provider's state directly
    // for simple cases if we don't need complex mock behaviour.
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeViewModelProvider.overrideWith(() => _MockLoadingHomeViewModel()),
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeViewModelProvider.overrideWith(() => _MockDataHomeViewModel(mockSummary)),
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

class _MockLoadingHomeViewModel extends _$HomeViewModel {
  @override
  FutureOr<StorageSummary> build() async {
    // Return a future that never completes to stay in the loading state
    return Completer<StorageSummary>().future; 
  }
}

class _MockDataHomeViewModel extends _$HomeViewModel {
  _MockDataHomeViewModel(this.summary);
  final StorageSummary summary;

  @override
  FutureOr<StorageSummary> build() {
    return summary;
  }
}
