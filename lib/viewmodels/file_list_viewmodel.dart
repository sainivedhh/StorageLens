import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:storage_lens/models/file_category.dart';
import 'package:storage_lens/models/file_item.dart';
import 'package:storage_lens/models/storage_summary.dart';
import 'package:storage_lens/viewmodels/home_viewmodel.dart';

part 'file_list_viewmodel.g.dart';

/// State for the [FileListViewModel], holding the current file list and sort mode.
class FileListState {
  /// Creates a [FileListState] with the provided [files] and [sortMode].
  const FileListState({
    required this.files,
    required this.sortMode,
  });

  /// The list of files currently being displayed.
  final List<FileItem> files;

  /// The active sort mode applied to [files].
  final SortMode sortMode;

  /// Returns a copy of this state with the given fields replaced.
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
  Future<FileListState> build(FileCategory category) async {
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

  /// Changes the sort mode and re-sorts the current file list.
  void setSortMode(SortMode mode) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final sortedFiles = List<FileItem>.from(currentState.files);

    switch (mode) {
      case SortMode.bySize:
        sortedFiles.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
      case SortMode.byDate:
        sortedFiles.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    }

    state = AsyncValue.data(
      currentState.copyWith(
        files: sortedFiles,
        sortMode: mode,
      ),
    );
  }

  /// Deletes a file from the file system, the database cache, and the UI state.
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
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
