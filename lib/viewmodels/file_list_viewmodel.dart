import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:storage_lens/models/file_category.dart';
import 'package:storage_lens/models/file_item.dart';
import 'package:storage_lens/models/storage_summary.dart';
import 'package:storage_lens/viewmodels/home_viewmodel.dart';

part 'file_list_viewmodel.g.dart';

/// State for the FileListViewModel, holding the files and current sort mode.
class FileListState {
  const FileListState({
    required this.files,
    required this.sortMode,
  });

  final List<FileItem> files;
  final SortMode sortMode;

  FileListState copyWith({
    List<FileItem>? files,
    SortMode? sortMode,
  }) {
    return FileListState(
      files: files ?? this.files,
      sortMode: sortMode ?? this.sortMode,
    );
  }
}

/// Manages the state for the File List Screen.
///
/// This ViewModel is scoped to a specific [FileCategory]. It derives its initial
/// list of files from the [HomeViewModel]'s summary, but can mutate the list
/// independently (e.g. when a file is deleted) before the next full scan.
@riverpod
class FileListViewModel extends _$FileListViewModel {
  @override
  FutureOr<FileListState> build(FileCategory category) async {
    // Watch the home view model to get the initial list of files
    // when the summary is updated.
    final summaryAsync = ref.watch(homeViewModelProvider);
    
    final files = summaryAsync.maybeWhen(
      data: (summary) => summary.filesForCategory(category, mode: SortMode.bySize),
      orElse: () => <FileItem>[],
    );

    return FileListState(
      files: files,
      sortMode: SortMode.bySize,
    );
  }

  /// Changes the sort mode and re-sorts the files.
  void setSortMode(SortMode mode) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final sortedFiles = List<FileItem>.from(currentState.files);
    
    switch (mode) {
      case SortMode.bySize:
        sortedFiles.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
        break;
      case SortMode.byDate:
        sortedFiles.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
        break;
    }

    state = AsyncValue.data(
      currentState.copyWith(
        files: sortedFiles,
        sortMode: mode,
      ),
    );
  }

  /// Deletes a file from the file system, the database, and the current state.
  Future<void> deleteFile(FileItem file) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    try {
      final storage = ref.read(storageServiceProvider);
      final db = ref.read(databaseServiceProvider);

      // 1. Delete from file system
      await storage.deleteFile(file.path);

      // 2. Delete from database cache
      await db.removeFile(file.id);

      // 3. Remove from current state so UI updates instantly
      final updatedFiles = List<FileItem>.from(currentState.files)
        ..removeWhere((f) => f.id == file.id);

      state = AsyncValue.data(currentState.copyWith(files: updatedFiles));

      // Note: A full implementation might also want to update the 
      // HomeViewModel's StorageSummary to reflect the freed space without 
      // requiring a full rescan. For this portfolio scope, deleting from
      // this view and letting the user tap "Rescan" on home is acceptable.
    } catch (e, st) {
      // In a real app, you might want to show a snackbar here via a 
      // side-effect stream or by re-throwing if the UI is catching it.
      // For simplicity, we just set the error state.
      state = AsyncValue.error(e, st);
    }
  }
}
