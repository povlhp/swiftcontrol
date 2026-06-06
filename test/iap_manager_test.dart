import 'package:bike_control/utils/iap/noop_iap_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NoopIAPManager', () {
    late NoopIAPManager noop;

    setUp(() {
      noop = NoopIAPManager();
    });

    test('isProEnabled returns true', () {
      expect(noop.isProEnabled, true);
    });

    test('canExecuteCommand returns true', () {
      expect(noop.canExecuteCommand, true);
    });

    test('hasActiveSubscription returns true', () {
      expect(noop.hasActiveSubscription, true);
    });

    test('isLoggedIn returns true', () {
      expect(noop.isLoggedIn, true);
    });

    test('commandsRemainingToday returns -1 (unlimited)', () {
      expect(noop.commandsRemainingToday, -1);
    });

    test('ensureProForFeature returns true', () async {
      final result = await noop.ensureProForFeature(null);
      expect(result, true);
    });

    test('initialize does not throw', () async {
      await expectLater(noop.initialize(), completes);
    });

    test('getStatusMessage returns Pro (free)', () {
      expect(noop.getStatusMessage(), 'Pro (free)');
    });
  });
}
