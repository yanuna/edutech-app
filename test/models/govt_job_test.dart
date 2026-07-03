import 'package:edutech_app/features/govt_jobs/models/govt_job.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GovtJob', () {
    test('parses a full job posting', () {
      final j = GovtJob.fromJson({
        'id': 3,
        'title': 'SSC CGL 2026',
        'slug': 'ssc-cgl-2026',
        'organization': 'Staff Selection Commission',
        'total_vacancies': 1200,
        'last_date': '2026-07-31',
        'is_expired': false,
        'is_closing_soon': true,
      });
      expect(j.id, 3);
      expect(j.title, 'SSC CGL 2026');
      expect(j.slug, 'ssc-cgl-2026');
      expect(j.totalVacancies, 1200);
      expect(j.isExpired, isFalse);
      expect(j.isClosingSoon, isTrue);
    });

    test('defaults strings/flags for a minimal payload', () {
      final j = GovtJob.fromJson({'id': 1});
      expect(j.title, '');
      expect(j.slug, '');
      expect(j.organization, isNull);
      expect(j.totalVacancies, isNull);
      expect(j.isExpired, isFalse);
      expect(j.isClosingSoon, isFalse);
    });
  });

  group('JobCategoryLite', () {
    test('parses name and slug with defaults', () {
      expect(
        JobCategoryLite.fromJson({'name': 'Banking', 'slug': 'banking'}).name,
        'Banking',
      );
      expect(JobCategoryLite.fromJson(const {}).slug, '');
    });
  });
}
