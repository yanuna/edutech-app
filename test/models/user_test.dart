import 'package:edutech_app/core/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User', () {
    test('parses a full user payload', () {
      final u = User.fromJson({
        'id': 11,
        'name': 'Anunay',
        'email': 'a@b.com',
        'avatar': 'http://img/a.png',
        'mobile_number': '9999999999',
        'role': 'admin',
        'is_blocked': false,
        'email_verified_at': '2026-01-01T00:00:00Z',
        'mobile_verified_at': '2026-01-02T00:00:00Z',
        'referral_code': 'REF123',
        'referred_by': 5,
      });
      expect(u.id, 11);
      expect(u.name, 'Anunay');
      expect(u.isAdmin, isTrue);
      expect(u.isEmailVerified, isTrue);
      expect(u.isMobileVerified, isTrue);
      // referred_by is coerced to a string even when sent as an int.
      expect(u.referredBy, '5');
    });

    test(
      'applies defaults and verification getters when fields are absent',
      () {
        final u = User.fromJson({'id': 1, 'name': 'Guest', 'email': 'g@x.com'});
        expect(u.role, 'user');
        expect(u.isAdmin, isFalse);
        expect(u.isBlocked, isFalse);
        expect(u.isEmailVerified, isFalse);
        expect(u.isMobileVerified, isFalse);
        expect(u.referredBy, isNull);
      },
    );

    test('copyWith overrides only the provided fields', () {
      final u = User.fromJson({
        'id': 1,
        'name': 'Old',
        'email': 'e@x.com',
        'mobile_number': '111',
        'role': 'user',
      });
      final updated = u.copyWith(name: 'New', mobileNumber: '222');
      expect(updated.name, 'New');
      expect(updated.mobileNumber, '222');
      // Untouched fields are preserved.
      expect(updated.id, 1);
      expect(updated.email, 'e@x.com');
      expect(updated.role, 'user');
    });
  });
}
