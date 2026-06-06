import 'package:bike_control/utils/core.dart' show core;
import 'package:bike_control/utils/settings/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Settings Supabase guard (non-commercial)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('core.isNonCommercial is the inverse of isCommercial', () {
      // Guard-rail: ensure the boolean logic used in the guard is correct.
      expect(core.isNonCommercial, equals(!core.isCommercial));
    });

    test('core.api returns null when isNonCommercial', () {
      // core.api always returns null regardless of commercial/non-commercial.
      if (core.isNonCommercial) {
        expect(core.api, isNull);
      } else {
        expect(core.api, isNull);
      }
    });

    test('settings object can be instantiated without Supabase', () async {
      // Minimal instantiation test: a Settings object can be created and
      // its SharedPreferences-backed methods work without Supabase at all.
      // This validates that the rest of Settings is decoupled from Supabase.
      final settings = Settings();
      settings.prefs = await SharedPreferences.getInstance();

      expect(settings.getReviewSessionCount(), 0);
      expect(settings.getShowExperimental(), isFalse);
    });
  });
}
