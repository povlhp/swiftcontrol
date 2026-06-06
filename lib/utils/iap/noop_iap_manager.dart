import 'package:bike_control/utils/iap/iap_manager.dart';

class NoopIAPManager extends IAPManager {
  NoopIAPManager() : super();

  @override
  bool get isLoggedIn => true;

  @override
  bool get hasActiveSubscription => true;

  @override
  bool get isProEnabled => true;

  @override
  bool get isProEnabledForCurrentDevice => true;

  @override
  bool get isProEnabledForCurrentDeviceOrDidPurchaseOld => true;

  @override
  bool get canExecuteCommand => true;

  @override
  int get commandsRemainingToday => -1;

  @override
  bool get hasTrialStarted => false;

  @override
  int get trialDaysRemaining => 0;

  @override
  bool get isTrialExpired => false;

  @override
  int get dailyCommandCount => 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> refreshEntitlementsOnAppStart() async {}

  @override
  Future<void> refreshEntitlementsOnResume() async {}

  @override
  Future<void> startTrial() async {}

  @override
  Future<void> purchaseFullVersion(context, {bool fromPaywall = false}) async {}

  @override
  Future<void> purchaseSubscription(context, {plan = SubscriptionPlan.monthly, bool fromPaywall = false}) async {}

  @override
  Future<void> restorePurchases() async {}

  @override
  bool get isUsingRevenueCat => false;

  @override
  bool get isWindows => false;

  @override
  bool get isWindowsLoggedIn => false;

  @override
  Future<bool> openBillingPortal(context) async => false;

  @override
  Future<bool> hasStripeCustomer() async => false;

  @override
  void dispose() {}

  @override
  Future<void> reset(bool fullReset) async {}

  @override
  Future<void> redeem(String purchaseId) async {}

  @override
  void setAttributes() {}

  @override
  String getStatusMessage() => 'Pro (free)';

  @override
  Future<void> incrementCommandCount() async {}

  @override
  Future<bool> ensureProForFeature(context, {bool isAllowedForOldPurchases = false}) async => true;

  @override
  bool get hasPurchasedBefore50RVC => true;

  @override
  DateTime? get premiumActiveUntil => null;

  @override
  bool get isOutsideStoreWindowsBuild => false;
}
