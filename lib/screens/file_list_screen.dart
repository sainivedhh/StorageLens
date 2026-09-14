import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storage_lens/models/file_category.dart';
import 'package:storage_lens/models/storage_summary.dart';
import 'package:storage_lens/viewmodels/file_list_viewmodel.dart';
import 'package:storage_lens/widgets/file_list_item.dart';

/// Screen displaying the files for a specific category.
class FileListScreen extends ConsumerWidget {
  const FileListScreen({
    super.key,
    required this.category,
  });

  final FileCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the view model state
    final stateAsync = ref.watch(fileListViewModelProvider(category));

    return Scaffold(
      appBar: AppBar(
        title: Text('${category.label} Files'),
        backgroundColor: category.color.withOpacity(0.1),
        actions: [
          stateAsync.maybeWhen(
            data: (state) => PopupMenuButton<SortMode>(
              icon: const Icon(Icons.sort),
              tooltip: 'Sort By',
              onSelected: (mode) {
                ref.read(fileListViewModelProvider(category).notifier).setSortMode(mode);
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: SortMode.bySize,
                  child: Row(
                    children: [
                      const Text('Size (Largest First)'),
                      if (state.sortMode == SortMode.bySize)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.check, size: 16),
                        ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: SortMode.byDate,
                  child: Row(
                    children: [
                      const Text('Date (Newest First)'),
                      if (state.sortMode == SortMode.byDate)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.check, size: 16),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: stateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
        data: (state) {
          if (state.files.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category.icon,
                    size: 64,
                    color: category.color.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No ${category.label.toLowerCase()} found.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: state.files.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final file = state.files[index];
              return FileListItem(
                file: file,
                onDelete: () {
                  ref.read(fileListViewModelProvider(category).notifier).deleteFile(file);
                },
              );
            },
          );
        },
      ),
    );
  }
}
