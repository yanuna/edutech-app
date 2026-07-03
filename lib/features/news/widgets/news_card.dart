import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/news_article.dart';
import '../providers/news_provider.dart';

class NewsCard extends ConsumerWidget {
  final NewsArticle article;

  const NewsCard({super.key, required this.article});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBookmarked = ref.watch(
      bookmarksProvider.select((s) => s.contains(article.id)),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image / Color Banner ───────────────────────────────────────────
          _ImageBanner(article: article),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Source chip + date + bookmark ─────────────────────────
                Row(
                  children: [
                    _SourceChip(article: article),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(article.publishedAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const Spacer(),
                    if (article.isPinned)
                      const Icon(
                        Icons.push_pin,
                        size: 14,
                        color: Color(0xFF7C3AED),
                      ),
                    _BookmarkButton(
                      articleId: article.id,
                      isBookmarked: isBookmarked,
                      ref: ref,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ── Title ─────────────────────────────────────────────────
                Text(
                  article.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF111827),
                    height: 1.4,
                  ),
                ),

                // ── Description ───────────────────────────────────────────
                if (article.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    article.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontFamily: 'Poppins',
                      height: 1.5,
                    ),
                  ),
                ],

                // ── Curator note (UPSC relevance) ────────────────────────
                if (article.isCurated && article.curatorNote != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFDDD6FE)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          size: 14,
                          color: Color(0xFF7C3AED),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            article.curatorNote!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6D28D9),
                              fontFamily: 'Poppins',
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Tags ──────────────────────────────────────────────────
                if (article.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: article.tags
                        .take(3)
                        .map((t) => _TagChip(label: t))
                        .toList(),
                  ),
                ],

                // ── Read More ─────────────────────────────────────────────
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _launchUrl(article.url),
                    icon: const Icon(Icons.open_in_new, size: 14),
                    label: const Text(
                      'Read Full Article',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: article.color,
                      side: BorderSide(
                        color: article.color.withValues(alpha: 0.4),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(dt);
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ImageBanner extends StatelessWidget {
  final NewsArticle article;
  const _ImageBanner({required this.article});

  @override
  Widget build(BuildContext context) {
    if (article.imageUrl != null && article.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Image.network(
          article.imageUrl!,
          height: 160,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _ColorBanner(article: article),
        ),
      );
    }
    return _ColorBanner(article: article);
  }
}

class _ColorBanner extends StatelessWidget {
  final NewsArticle article;
  const _ColorBanner({required this.article});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: article.color.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      alignment: Alignment.center,
      child: Text(
        article.sourceLabel,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: 22,
          color: article.color.withValues(alpha: 0.4),
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  final NewsArticle article;
  const _SourceChip({required this.article});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: article.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        article.sourceLabel,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 10,
          color: article.color,
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF374151),
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _BookmarkButton extends StatelessWidget {
  final String articleId;
  final bool isBookmarked;
  final WidgetRef ref;

  const _BookmarkButton({
    required this.articleId,
    required this.isBookmarked,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
        size: 18,
        color: isBookmarked ? const Color(0xFF4F46E5) : Colors.grey,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: () => ref.read(bookmarksProvider.notifier).toggle(articleId),
    );
  }
}
