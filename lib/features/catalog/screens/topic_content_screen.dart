import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/styled_html_view.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../core/providers/catalog_provider.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/models/catalog.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/ad_banner_widget.dart';

class TopicContentScreen extends ConsumerStatefulWidget {
  final int topicId;
  final String topicName;
  const TopicContentScreen({
    super.key,
    required this.topicId,
    required this.topicName,
  });

  @override
  ConsumerState<TopicContentScreen> createState() => _TopicContentScreenState();
}

class _TopicContentScreenState extends ConsumerState<TopicContentScreen> {
  YoutubePlayerController? _ytController;

  @override
  void dispose() {
    _ytController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(topicContentProvider(widget.topicId));
    final subStatus = ref.watch(subscriptionStatusProvider);
    final lang = ref.watch(contentLanguageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topicName),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SegmentedButton<String>(
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: const [
                ButtonSegment(value: 'en', label: Text('EN')),
                ButtonSegment(value: 'hi', label: Text('हिं')),
              ],
              selected: {lang},
              showSelectedIcon: false,
              onSelectionChanged: (s) =>
                  ref.read(contentLanguageProvider.notifier).set(s.first),
            ),
          ),
        ],
      ),
      body: content.when(
        data: (items) {
          // Check if paywall should be shown
          final isLocked =
              subStatus.whenOrNull(data: (s) => !s.hasAccess) ?? false;

          if (isLocked) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: PaywallWidget(
                  onSubscribe: () => context.push('/profile/plans'),
                ),
              ),
            );
          }

          // A single HTML document (the common case) is rendered as a lazy
          // ListView so large topics — some are 100KB+ — lay out their content
          // on demand and scroll smoothly, instead of building the whole tree
          // at once (which janked) or in a WebView (which crashed the render
          // thread on big documents).
          if (items.length == 1 && items.first.contentType == 'html') {
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: AdBannerWidget(),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: StyledHtmlView(
                      items.first.htmlContent ?? '',
                      renderMode: RenderMode.listView,
                    ),
                  ),
                ),
              ],
            );
          }

          // Mixed / multiple content (videos, PDFs, several blocks).
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: AdBannerWidget(),
                );
              }
              return _ContentBlock(content: items[i - 1]);
            },
          );
        },
        loading: () => const LoadingWidget(message: 'Loading content...'),
        error: (e, _) => ErrorRetryWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(topicContentProvider(widget.topicId)),
        ),
      ),
    );
  }
}

class _ContentBlock extends StatefulWidget {
  final TopicContent content;
  const _ContentBlock({required this.content});

  @override
  State<_ContentBlock> createState() => _ContentBlockState();
}

class _ContentBlockState extends State<_ContentBlock> {
  YoutubePlayerController? _ytController;

  @override
  void initState() {
    super.initState();
    if (widget.content.contentType == 'video' &&
        widget.content.youtubeVideoId != null) {
      _ytController = YoutubePlayerController(
        initialVideoId: widget.content.youtubeVideoId!,
        flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
      );
    }
  }

  @override
  void dispose() {
    _ytController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.content;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: switch (c.contentType) {
        // Only render the player when the controller was actually initialised
        // (a 'video' row with a null youtube_video_id would otherwise crash).
        'video' when _ytController != null => _VideoBlock(
          controller: _ytController!,
          title: c.title,
        ),
        'html' => _HtmlBlock(html: c.htmlContent ?? '', title: c.title),
        'pdf' => _PdfBlock(url: c.fileUrl ?? '', title: c.title),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _VideoBlock extends StatelessWidget {
  final YoutubePlayerController controller;
  final String? title;
  const _VideoBlock({required this.controller, this.title});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (title != null) ...[
        Text(
          title!,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
      ],
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: YoutubePlayer(
          controller: controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: const Color(0xFF4F46E5),
        ),
      ),
    ],
  );
}

class _HtmlBlock extends StatelessWidget {
  final String html;
  final String? title;
  const _HtmlBlock({required this.html, this.title});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const Divider(),
          ],
          StyledHtmlView(html),
        ],
      ),
    ),
  );
}

class _PdfBlock extends StatelessWidget {
  final String url;
  final String? title;
  const _PdfBlock({required this.url, this.title});

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(
        Icons.picture_as_pdf,
        color: Colors.redAccent,
        size: 36,
      ),
      title: Text(
        title ?? 'PDF Document',
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: const Text(
        'Tap to open',
        style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
      ),
      trailing: const Icon(Icons.open_in_new),
      onTap: () {
        // URL launch handled externally
      },
    ),
  );
}
