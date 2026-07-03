import 'package:edutech_app/core/models/catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Subject / Chapter / Topic', () {
    test('parses a subject with defaults', () {
      final s = Subject.fromJson({'id': 1, 'name': 'Maths'});
      expect(s.id, 1);
      expect(s.name, 'Maths');
      expect(s.isPaid, isFalse);
      expect(s.order, 0);
    });

    test('parses a chapter linked to its subject', () {
      final c = Chapter.fromJson({
        'id': 2,
        'subject_id': 1,
        'name': 'Algebra',
        'is_paid': true,
        'order': 3,
      });
      expect(c.subjectId, 1);
      expect(c.isPaid, isTrue);
      expect(c.order, 3);
    });

    test('parses a topic linked to its chapter', () {
      final t = Topic.fromJson({'id': 5, 'chapter_id': 2, 'name': 'Linear Eq'});
      expect(t.chapterId, 2);
      expect(t.name, 'Linear Eq');
    });
  });

  group('TopicContent', () {
    test('exposes the first file url via fileUrl', () {
      final tc = TopicContent.fromJson({
        'id': 1,
        'content_type': 'pdf',
        'file_urls': ['http://a/1.pdf', 'http://a/2.pdf'],
      });
      expect(tc.fileUrls, hasLength(2));
      expect(tc.fileUrl, 'http://a/1.pdf');
    });

    test('fileUrl is null when there are no files', () {
      final tc = TopicContent.fromJson({'id': 1, 'content_type': 'html'});
      expect(tc.fileUrls, isEmpty);
      expect(tc.fileUrl, isNull);
    });
  });
}
