import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/entity_provider.dart';
import '../../learn/screens/articles_list_screen.dart' show ArticleCardTile;

/// Browse typed entities — Schemes, Committees, Supreme Court cases, Reports.
class EntitiesScreen extends ConsumerStatefulWidget {
  const EntitiesScreen({super.key});

  @override
  ConsumerState<EntitiesScreen> createState() => _EntitiesScreenState();
}

class _EntitiesScreenState extends ConsumerState<EntitiesScreen> {
  static const _types = [
    ('scheme', 'Schemes'),
    ('committee', 'Committees'),
    ('sc_case', 'SC Cases'),
    ('report', 'Reports'),
    ('article', 'Const. Articles'),
  ];
  String _type = 'scheme';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(entitiesProvider(_type));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final t in _types)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(label: Text(t.$2), selected: _type == t.$1, onSelected: (_) => setState(() => _type = t.$1)),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _Message(icon: Icons.wifi_off_rounded, title: 'Could not load', subtitle: 'Try again.', onRetry: () => ref.invalidate(entitiesProvider(_type))),
        data: (items) => items.isEmpty
            ? const _Message(icon: Icons.account_balance_outlined, title: 'Nothing here yet', subtitle: 'Entities of this type will appear here once tagged.')
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(entitiesProvider(_type)),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final e = items[i];
                    return ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: .5))),
                      leading: const Icon(Icons.account_balance_outlined, color: Color(0xFF6366F1)),
                      title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: e.articlesCount == 0
                          ? const Icon(Icons.chevron_right_rounded)
                          : Row(mainAxisSize: MainAxisSize.min, children: [
                              Text('${e.articlesCount}', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF6366F1))),
                              const Icon(Icons.chevron_right_rounded),
                            ]),
                      onTap: () => context.push('/entities/${e.slug}'),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class EntityDetailScreen extends ConsumerWidget {
  final String slug;
  const EntityDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(entityDetailProvider(slug));

    return Scaffold(
      appBar: AppBar(title: async.maybeWhen(data: (d) => Text(d.name), orElse: () => const Text('Entity'))),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _Message(icon: Icons.wifi_off_rounded, title: 'Could not load', subtitle: 'Try again.', onRetry: () => ref.invalidate(entityDetailProvider(slug))),
        data: (d) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (d.description != null && d.description!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: .07), borderRadius: BorderRadius.circular(12)),
                child: Text(d.description!, style: const TextStyle(height: 1.5)),
              ),
              const SizedBox(height: 16),
            ],
            Text(d.articles.isEmpty ? 'No linked articles yet' : 'Related Articles',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            for (final a in d.articles) ArticleCardTile(card: a),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;
  const _Message({required this.icon, required this.title, required this.subtitle, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 46, color: Colors.grey.shade400),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
          if (onRetry != null) ...[const SizedBox(height: 16), FilledButton.tonal(onPressed: onRetry, child: const Text('Retry'))],
        ]),
      ),
    );
  }
}
