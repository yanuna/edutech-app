import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/catalog_provider.dart';
import '../../../core/models/catalog.dart';
import '../../../shared/widgets/app_widgets.dart';

class ChaptersScreen extends ConsumerWidget {
  final int subjectId;
  final String subjectName;
  const ChaptersScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapters = ref.watch(chaptersProvider(subjectId));

    return Scaffold(
      appBar: AppBar(title: Text(subjectName)),
      body: chapters.when(
        data: (list) => ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _ChapterTile(chapter: list[i], index: i + 1),
        ),
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: 5,
          itemBuilder: (_, _) => const ShimmerCard(height: 80),
        ),
        error: (e, _) => ErrorRetryWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(chaptersProvider(subjectId)),
        ),
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  final Chapter chapter;
  final int index;
  const _ChapterTile({required this.chapter, required this.index});

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFEEF2FF),
        child: Text(
          '$index',
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFF4F46E5),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(
        chapter.name,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (chapter.isPaid)
            const Icon(Icons.lock_outline, size: 16, color: Colors.amber),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => context.push(
        '/subjects/${chapter.subjectId}/chapters/${chapter.id}/topics?name=${Uri.encodeComponent(chapter.name)}',
      ),
    ),
  );
}
