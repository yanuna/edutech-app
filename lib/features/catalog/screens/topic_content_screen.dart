import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/styled_html_view.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../core/api/api_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/catalog_provider.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/models/catalog.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/ad_banner_widget.dart';
import '../../../shared/widgets/secure_pdf_viewer.dart';
import '../../../shared/widgets/secure_epub_viewer.dart';

/// Streams a private document from its short-lived signed URL into memory. The
/// URL already carries its own signature auth, so no bearer token is needed;
/// plaintext bytes live only in RAM and are handed straight to the secure viewer.
Future<Uint8List> _fetchSignedBytes(String url) async {
  final res = await ApiClient.instance.dio.get<List<int>>(
    url,
    options: Options(
      responseType: ResponseType.bytes,
      // Required by the backend guard on /api/secure-file — direct (header-less)
      // access is refused so a leaked URL can't be opened in a browser.
      headers: const {'X-Requested-With': 'XMLHttpRequest'},
    ),
  );
  return Uint8List.fromList(res.data ?? const []);
}

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

          // A single uploaded document (PDF/EPUB) fills the screen with the
          // inline secure viewer — view-only, searchable, no download/share.
          // This replaces the old "downloadable attachment" behaviour.
          if (items.length == 1 &&
              (items.first.contentType == 'pdf' ||
                  items.first.contentType == 'epub')) {
            final item = items.first;
            final url = item.fileUrl;
            if (url == null) {
              return const Center(child: Text('Document unavailable.'));
            }
            final watermark = ref.watch(authProvider).user?.email;
            final title = item.title ?? widget.topicName;
            return item.contentType == 'epub'
                ? SecureEpubViewer(
                    url: url,
                    title: title,
                    watermark: watermark,
                    embedded: true,
                  )
                : SecurePdfViewer.loader(
                    () => _fetchSignedBytes(url),
                    title: title,
                    watermark: watermark,
                    embedded: true,
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

          // Mixed / multiple content (videos, documents, several blocks).
          final watermark = ref.watch(authProvider).user?.email;
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
              return _ContentBlock(
                content: items[i - 1],
                watermark: watermark,
              );
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
  final String? watermark;
  const _ContentBlock({required this.content, this.watermark});

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
        'pdf' || 'epub' => _DocumentBlock(
          content: c,
          watermark: widget.watermark,
        ),
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

/// Renders an uploaded PDF/EPUB inline with the secure, view-only viewer instead
/// of a downloadable attachment. Fixed height so it embeds cleanly inside the
/// scrolling content list; the viewer manages its own paging within that box.
class _DocumentBlock extends StatelessWidget {
  final TopicContent content;
  final String? watermark;
  const _DocumentBlock({required this.content, this.watermark});

  @override
  Widget build(BuildContext context) {
    final url = content.fileUrl;
    if (url == null || url.isEmpty) return const SizedBox.shrink();

    final isEpub = content.contentType == 'epub';
    final title = content.title ?? (isEpub ? 'E-Book' : 'PDF Document');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 520,
            child: isEpub
                ? SecureEpubViewer(
                    url: url,
                    title: title,
                    watermark: watermark,
                    embedded: true,
                  )
                : SecurePdfViewer.loader(
                    () => _fetchSignedBytes(url),
                    title: title,
                    watermark: watermark,
                    embedded: true,
                  ),
          ),
        ),
      ],
    );
  }
}
