import 'dart:async';
import 'dart:io';

import 'package:bike_control/gen/l10n.dart';
import 'package:bike_control/pages/paywall.dart';
import 'package:bike_control/utils/core.dart';
import 'package:bike_control/utils/iap/noop_iap_manager.dart';
import 'package:bike_control/utils/windows_store_environment.dart';
import 'package:bike_control/widgets/go_pro_dialog.dart';
import 'package:bike_control/widgets/ui/toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

enum SubscriptionPlan {
  monthly,
  yearly,
}

/// Unified IAP manager that handles platform-specific IAP services.
class IAPManager {
  static IAPManager? _instance;
  static IAPManager get instance {
    if (core.isNonCommercial) {
      _instance ??= NoopIAPManager();
      return _instance!;
    }
    _instance ??= IAPManager();
    return _instance!;
  }

  static const String premiumMonthlyProductKey = 'premium_monthly';
  static const String premiumYearlyProductKey = 'premium_yearly';
  static const String fullVersionProductKey = 'full_version';
  static int dailyCommandLimit = 15;

  StreamSubscription<dynamic>? _authSubscription;
  bool _isInitialized = false;

  final dynamic deviceIdentity = null;
  late final dynamic deviceManagement = null;
  late final dynamic entitlements = null;

  ValueNotifier<bool> isPurchased = ValueNotifier<bool>(false);
  ValueNotifier<bool> isLocalPro = ValueNotifier<bool>(false);

  IAPManager();

  bool get isLoggedIn => core.api?.auth?.currentSession != null;

  bool get hasActiveSubscription =>
      (isLoggedIn && (entitlements.hasActive(premiumMonthlyProductKey)) ||
          entitlements.hasActive(premiumYearlyProductKey)) ||
      (!isLoggedIn && isLocalPro.value);

  bool get isProEnabled => hasActiveSubscription && (isLoggedIn || (!isLoggedIn && isLocalPro.value));

  bool get isProEnabledForCurrentDevice {
    if (!_isInitialized) return false;
    return hasActiveSubscription && ((isLoggedIn && entitlements.isRegisteredDevice) || (!isLoggedIn && isLocalPro.value));
  }

  bool get isProEnabledForCurrentDeviceOrDidPurchaseOld {
    if (!_isInitialized) return false;
    return isProEnabledForCurrentDevice || hasPurchasedBefore50RVC;
  }

  bool get hasPurchasedBefore50RVC => false;

  DateTime? get premiumActiveUntil =>
      entitlements.activeUntil(premiumMonthlyProductKey) ?? entitlements.activeUntil(premiumYearlyProductKey);

  /// Initialize the IAP manager.
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (core.isNonCommercial) return;

    final prefs = FlutterSecureStorage(aOptions: AndroidOptions());
    await entitlements.initialize();
    entitlements.addListener(_onEntitlementsChanged);
    _bindAuthLifecycle();

    if (kIsWeb) {
      _isInitialized = true;
      return;
    }

    _isInitialized = true;
  }

  /// Called on app start when a session may already exist.
  Future<void> refreshEntitlementsOnAppStart() async {
    await entitlements.refresh(force: true);
    _syncPurchaseFlagFromEntitlements();
  }

  /// Called on app resume to refresh stale entitlement cache.
  Future<void> refreshEntitlementsOnResume() async {
    await entitlements.refresh();
    _syncPurchaseFlagFromEntitlements();
  }

  /// Check if the trial period has started.
  bool get hasTrialStarted {
    if (isOutsideStoreWindowsBuild) {
      return true;
    }
    return false;
  }

  /// Start the trial period.
  Future<void> startTrial() async {
  }

  /// Get the number of days remaining in the trial.
  int get trialDaysRemaining {
    if (isOutsideStoreWindowsBuild) {
      return 0;
    }
    return 0;
  }

  /// Check if the trial has expired.
  bool get isTrialExpired {
    if (isProEnabled) {
      return false;
    }
    if (isOutsideStoreWindowsBuild && !isPurchased.value) {
      return true;
    }
    return false;
  }

  /// Check if the user can execute a command.
  bool get canExecuteCommand {
    if (isProEnabled) return true;
    return true;
  }

  /// Get the number of commands remaining today (for free tier after trial).
  int get commandsRemainingToday {
    if (isProEnabled) {
      return -1;
    }
    return -1;
  }

  /// Get the daily command count.
  int get dailyCommandCount {
    return 0;
  }

  /// Increment the daily command count.
  Future<void> incrementCommandCount() async {
    if (isProEnabled) {
      return;
    }
  }

  /// Get a status message for the user.
  String getStatusMessage() {
    final activeUntil = premiumActiveUntil;
    final expiryInfo = activeUntil != null ? '\nexpires at ${_formatDate(activeUntil)}' : '';

    if (kIsWeb) {
      return "Web";
    } else if (isProEnabledForCurrentDevice) {
      return 'Pro$expiryInfo';
    } else if (isProEnabled) {
      return 'Pro (unregistered device)$expiryInfo';
    } else if (isPurchased.value) {
      return AppLocalizations.current.fullVersion;
    } else if (isOutsideStoreWindowsBuild) {
      return AppLocalizations.current.trialExpired(dailyCommandLimit);
    } else if (!hasTrialStarted) {
      return '${trialDaysRemaining} day trial available';
    } else if (!isTrialExpired) {
      return AppLocalizations.current.trialDaysRemaining(trialDaysRemaining);
    } else {
      return AppLocalizations.current.commandsRemainingToday(commandsRemainingToday, dailyCommandLimit);
    }
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    // when today return full time, otherwise just date
    final now = DateTime.now();
    if (local.year == now.year && local.month == now.month && local.day == now.day) {
      return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    } else {
      return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}';
    }
  }

  /// Purchase the full version.
  Future<void> purchaseFullVersion(BuildContext context, {bool fromPaywall = false}) async {
    if (isOutsideStoreWindowsBuild) {
      if (!fromPaywall) {
        return _showPaywall(context, false);
      }
      return;
    }
    if ((Platform.isWindows || Platform.isMacOS) && !fromPaywall) {
      return _showPaywall(context, false);
    }
  }

  /// Purchase a subscription.
  Future<void> purchaseSubscription(
    BuildContext context, {
    SubscriptionPlan plan = SubscriptionPlan.monthly,
    bool fromPaywall = false,
  }) async {
    if ((Platform.isWindows || Platform.isMacOS) && !fromPaywall) {
      return _showPaywall(context, true);
    }
  }

  Future<void> _showPaywall(BuildContext context, bool subscription) async {
    openDrawer(
      context: context,
      builder: (c) => Paywall(defaultToFullVersion: !subscription),
      position: OverlayPosition.bottom,
    );
  }

  /// Restore previous purchases.
  Future<void> restorePurchases() async {
    _syncPurchaseFlagFromEntitlements();
  }

  /// Check if RevenueCat is being used.
  bool get isUsingRevenueCat => false;

  /// Check if running on Windows
  bool get isWindows => false;

  bool get isOutsideStoreWindowsBuild =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows && WindowsStoreEnvironment.isOutsideStoreCached;

  /// Check if user is logged in (Windows Stripe requires this)
  bool get isWindowsLoggedIn => false;

  /// Open Stripe Billing Portal (Windows only)
  /// Returns false if user has no Stripe customer (should hide button)
  Future<bool> openBillingPortal(BuildContext context) async {
    return false;
  }

  /// Check if user has a Stripe customer record (Windows only)
  Future<bool> hasStripeCustomer() async {
    return false;
  }

  /// Dispose the manager.
  void dispose() {
    _authSubscription?.cancel();
    entitlements.removeListener(_onEntitlementsChanged);
  }

  Future<void> reset(bool fullReset) async {
    isPurchased.value = false;
    await entitlements.clearCache();
  }

  Future<void> redeem(String purchaseId) async {
    await entitlements.refresh(force: true);
    _syncPurchaseFlagFromEntitlements();
  }

  void setAttributes() {
  }

  void setWinBoughtBefore50() {
  }

  void _bindAuthLifecycle() {
    if (core.api == null) return;
    _authSubscription ??= core.api.auth.onAuthStateChange.listen((data) {
      // No-op in non-commercial build
    });
  }

  void _onEntitlementsChanged() {
    _syncPurchaseFlagFromEntitlements();
  }

  void _syncPurchaseFlagFromEntitlements() {
    if (isProEnabled) {
      isPurchased.value = true;
    } else if (isOutsideStoreWindowsBuild && entitlements.hasActive(fullVersionProductKey)) {
      isPurchased.value = true;
    }
  }

  Future<bool> ensureProForFeature(BuildContext context, {bool isAllowedForOldPurchases = false}) async {
    if (isProEnabledForCurrentDevice || (isAllowedForOldPurchases && hasPurchasedBefore50RVC)) {
      return true;
    } else if (isProEnabled) {
      buildToast(title: AppLocalizations.of(context).currentDeviceIsNotRegistered);
      return isProEnabledForCurrentDevice;
    } else {
      await showGoProDialog(context);
    }
    return IAPManager.instance.hasActiveSubscription;
  }
}
