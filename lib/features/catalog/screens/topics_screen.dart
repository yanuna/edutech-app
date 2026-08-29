import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/catalog_provider.dart';
import '../../../core/models/catalog.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../core/api/api_client.dart';

class TopicsScreen extends ConsumerWidget {
  final int subjectId;
  final int chapterId;
  final String chapterName;
  const TopicsScreen({
    super.key,
    required this.subjectId,
    required this.chapterId,
    required this.chapterName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topics = ref.watch(topicsProvider(chapterId));

    return Scaffold(
      appBar: AppBar(title: Text(chapterName)),
      body: topics.when(
        data: (list) => ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) =>
              _TopicTile(subjectId: subjectId, topic: list[i], index: i + 1),
        ),
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: 5,
          itemBuilder: (_, _) => const ShimmerCard(height: 72),
        ),
        error: (e, _) => ErrorRetryWidget(
          message: apiErrorMessage(e),
          onRetry: () => ref.invalidate(topicsProvider(chapterId)),
        ),
      ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  final int subjectId;
  final Topic topic;
  final int index;
  const _TopicTile({
    required this.subjectId,
    required this.topic,
    required this.index,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.article_outlined,
          color: const Color(0xFF4F46E5),
          size: 20,
        ),
      ),
      title: Text(
        topic.name,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: topic.isPaid
          ? const Icon(Icons.lock_outline, size: 16, color: Colors.amber)
          : const Icon(Icons.chevron_right),
      onTap: () => context.push(
        '/subjects/$subjectId/chapters/${topic.chapterId}/topics/${topic.id}/content?name=${Uri.encodeComponent(topic.name)}',
      ),
    ),
  );
}
