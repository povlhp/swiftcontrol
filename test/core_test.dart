import 'package:bike_control/utils/core.dart' show core;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Core - isCommercial / isNonCommercial', () {
    test('isNonCommercial is the logical inverse of isCommercial', () {
      expect(core.isNonCommercial, equals(!core.isCommercial));
    });

    test('defaults to commercial when NO_COMMERCIAL is not set', () {
      // In a regular test run (without --dart-define=NO_COMMERCIAL=true),
      // isCommercial defaults to true.
      expect(core.isCommercial, isTrue);
      expect(core.isNonCommercial, isFalse);
    });
  });
}
