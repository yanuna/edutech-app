import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/search_provider.dart';

/// Universal search across articles, MCQs, PYQs, current affairs and entities.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = v.trim());
    });
  }

  static const _titles = {
    'articles': 'Articles',
    'mcqs': 'MCQs',
    'pyqs': 'PYQs',
    'current_affairs': 'Current Affairs',
    'entities': 'Schemes & Entities',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          decoration: InputDecoration(
            hintText: 'Search articles, MCQs, PYQs…',
            border: InputBorder.none,
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                    },
                  ),
          ),
        ),
      ),
      body: _query.length < 2 ? _prompt() : _results(),
    );
  }

  Widget _prompt() => const _Hint(
        icon: Icons.search_rounded,
        title: 'Search everything',
        subtitle: 'Find articles, questions, previous-year papers, current affairs and schemes — all in one place.',
      );

  Widget _results() {
    final async = ref.watch(searchProvider(_query));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => _Hint(
        icon: Icons.wifi_off_rounded,
        title: 'Search failed',
        subtitle: 'Check your connection and try again.',
        onRetry: () => ref.invalidate(searchProvider(_query)),
      ),
      data: (results) {
        if (results.isEmpty) {
          return _Hint(icon: Icons.search_off_rounded, title: 'No results', subtitle: 'Nothing matched "${results.query}". Try different keywords.');
        }
        final order = ['articles', 'mcqs', 'pyqs', 'current_affairs', 'entities'];
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            for (final key in order)
              if ((results.groups[key] ?? []).isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                  child: Text(_titles[key] ?? key, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6366F1))),
                ),
                for (final hit in results.groups[key]!) _HitTile(hit: hit),
              ],
          ],
        );
      },
    );
  }
}

class _HitTile extends StatelessWidget {
  final SearchHit hit;
  const _HitTile({required this.hit});

  IconData get _icon => switch (hit.group) {
    'articles' => Icons.article_outlined,
    'mcqs' => Icons.quiz_outlined,
    'pyqs' => Icons.history_edu_outlined,
    'current_affairs' => Icons.newspaper_outlined,
    'entities' => Icons.account_balance_outlined,
    _ => Icons.circle_outlined,
  };

  Future<void> _onTap(BuildContext context) async {
    if (hit.group == 'articles' && hit.slug != null) {
      context.push('/learn/article/${hit.slug}');
    } else if (hit.group == 'current_affairs' && hit.url != null) {
      final uri = Uri.tryParse(hit.url!);
      if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tappable = (hit.group == 'articles' && hit.slug != null) || (hit.group == 'current_affairs' && hit.url != null);
    return ListTile(
      leading: Icon(_icon, color: const Color(0xFF6366F1)),
      title: Text(hit.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
      subtitle: hit.subtitle == null ? null : Text(hit.subtitle!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      trailing: tappable ? const Icon(Icons.chevron_right_rounded) : null,
      onTap: tappable ? () => _onTap(context) : null,
    );
  }
}

class _Hint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;
  const _Hint({required this.icon, required this.title, required this.subtitle, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
