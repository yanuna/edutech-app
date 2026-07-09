import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edutech_app/shared/widgets/styled_html_view.dart';

const _notesHtml = '''
<div class="container">
  <div class="header-section"><h1>Ancient India</h1></div>
  <h2 class="section-title">Introduction</h2>
  <p>Text with a <span class="highlight">highlighted</span> term.</p>
  <div class="timeline">
    <div class="timeline-item">
      <span class="timeline-date">3300 BCE</span>
      <div class="timeline-title">Harappa</div>
      <div class="timeline-desc">Early <span class="highlight">urban</span> phase.</div>
    </div>
    <div class="timeline-item">
      <span class="timeline-date">1500 BCE</span>
      <div class="timeline-title">Vedic</div>
      <div class="timeline-desc">Later phase.</div>
    </div>
  </div>
  <div class="upsc-alert">An important alert.</div>
  <div class="debate-box">A scholarly debate.</div>
  <div class="footer-note">End of Master Notes.</div>
</div>
''';

void main() {
  Future<void> pump(WidgetTester tester, {required Brightness brightness}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: const Scaffold(
          body: SingleChildScrollView(child: StyledHtmlView(_notesHtml)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders notes components (timeline/callouts) without error — light', (tester) async {
    await pump(tester, brightness: Brightness.light);
    expect(tester.takeException(), isNull);
    // Timeline items are rendered by the custom widget (date badge + title).
    expect(find.text('3300 BCE'), findsOneWidget);
    expect(find.text('1500 BCE'), findsOneWidget);
    expect(find.text('Harappa'), findsOneWidget);
    expect(find.text('Vedic'), findsOneWidget);
  });

  testWidgets('renders notes components without error — dark', (tester) async {
    await pump(tester, brightness: Brightness.dark);
    expect(tester.takeException(), isNull);
    expect(find.text('Harappa'), findsOneWidget);
  });
}
