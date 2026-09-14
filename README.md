# StorageLens

![StorageLens CI](https://github.com/<your-username>/storagelens/actions/workflows/ci.yml/badge.svg)

A cross-platform storage management tool built with Flutter for Android and Windows Desktop. StorageLens helps users quickly identify what is taking up space on their device by categorizing files and visualising storage usage.

*Note: Screenshots will be added here once the app is deployed to a physical device.*

## Features

- **Categorized Storage Breakdown:** Scans the file system and groups files into Images, Videos, Documents, Audio, and Other.
- **Interactive Pie Chart:** Visualises the proportion of storage used by each category.
- **File Management:** Browse files within categories (sorted by size or date) and permanently delete unneeded files to free up space.
- **Instant Launch via SQLite Caching:** Scan results are cached locally using `sqflite`. Reopening the app instantly shows the latest data without waiting for a full re-scan.
- **Cross-Platform Abstraction:** Built with a clean interface layer that allows swapping the underlying file-system scanner (e.g. Android `dart:io` vs Windows Desktop).

## Architecture

This project was built as a portfolio piece demonstrating clean architecture and modern Flutter best practices.

### Key Decisions
1. **MVVM with Riverpod:** Separates business logic into ViewModels (`AsyncNotifier`), keeping the UI widgets purely declarative. Riverpod provides compile-safe dependency injection.
2. **Layer-First Folder Structure:** Code is organized by technical concern (`models`, `services`, `viewmodels`, `screens`, `widgets`), which is standard for small-to-medium Flutter projects.
3. **StorageService Abstraction:** The `StorageService` interface isolates platform-specific file access APIs from the rest of the app. This makes ViewModels trivially unit-testable and allows the Windows desktop implementation to be a stub (or fully implemented later) without touching UI code.
4. **Pure Dart Models:** Data models (`FileItem`, `StorageSummary`) have zero dependencies on Flutter, meaning they can be rigorously unit tested.

### Code Organization
```
lib/
├── models/         # Pure Dart data classes (FileItem, FileCategory, StorageSummary)
├── services/       # Platform interfaces & SQLite caching (StorageService, DatabaseService)
├── viewmodels/     # Riverpod AsyncNotifiers (HomeViewModel, FileListViewModel)
├── screens/        # Full-page UI widgets (HomeScreen, FileListScreen)
└── widgets/        # Reusable UI components (StoragePieChart, CategoryCard)
```

## Android Permissions Note

To perform a comprehensive scan of the device (including PDFs, ZIPs, etc. outside of standard media folders), this app requests the `MANAGE_EXTERNAL_STORAGE` permission on Android 11+ (API 30+). 

**Google Play Store Policy:** If publishing to the Play Store, this permission triggers a manual review. You must provide a compelling justification for "All Files Access". If this app were to be published commercially without needing a full-disk scan, the manifest would need to be downgraded to only request `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, and `READ_MEDIA_AUDIO`.

## Setup and Development

### Prerequisites
- Flutter SDK (`>=3.24.x`)
- Android Studio or VS Code with Flutter extensions

### Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/<your-username>/storagelens.git
   cd storagelens
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run code generation (required for Riverpod providers):
   ```bash
   dart run build_runner build -d
   ```

4. Run the app on an Android emulator/device or Windows desktop:
   ```bash
   flutter run
   ```

### Running Tests

The project includes both unit tests (testing pure Dart logic) and widget tests.

```bash
# Run all tests
flutter test

# Run strict linting (configured via very_good_analysis)
flutter analyze
```

## CI/CD

A GitHub Actions workflow is configured in `.github/workflows/ci.yml`. On every push and PR, it:
1. Installs dependencies
2. Generates Riverpod code
3. Runs strict static analysis (`flutter analyze --fatal-infos`)
4. Runs the test suite
5. (On push to `main`) Builds a release APK and uploads it as an artifact.
