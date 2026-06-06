import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bike_control/gen/l10n.dart';
import 'package:bike_control/utils/core.dart';
import 'package:bike_control/utils/i18n_extension.dart';
import 'package:bike_control/utils/iap/iap_manager.dart';
import 'package:bike_control/utils/requirements/windows.dart';
import 'package:bike_control/widgets/menu.dart';
import 'package:bike_control/widgets/title.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class LoginPage extends StatefulWidget {
  final bool pushed;
  final VoidCallback? onBack;
  const LoginPage({super.key, required this.pushed, this.onBack});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final IAPManager _iapManager = IAPManager.instance;

  @override
  Widget build(BuildContext context) {
    if (core.isNonCommercial || core.api == null) {
      return _buildNonCommercialStub(context);
    }
    final session = core.api?.auth?.currentSession;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: session == null ? _buildSignedOut(context) : _buildSignedIn(context, session),
        ),
      ),
    );
  }

  Widget _buildSignedOut(BuildContext context) {
    return Column(
      spacing: 32,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.account_circle,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Column(
          spacing: 8,
          children: [
            Text(
              'BikeControl',
            ).large,
            Text(
              AppLocalizations.of(context).signInToSyncYourSubscriptionAndManageDevices,
            ).small.muted,
          ],
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              spacing: 16,
              mainAxisSize: MainAxisSize.min,
              children: [
                Button.secondary(
                  leading: const Icon(Icons.code, size: 18),
                  onPressed: _signInWithGithub,
                  child: const Text('Sign in with GitHub'),
                ),
                Button.secondary(
                  leading: const Icon(Icons.facebook, size: 18),
                  onPressed: _signInWithFacebook,
                  child: const Text('Sign in with Facebook'),
                ),
              ],
            ),
          ),
        ),
        if (!kIsWeb)
          Button.ghost(
            leading: const Icon(Icons.mail_outline, size: 16),
            onPressed: _openMailFallback,
            child: Text(context.i18n.dontWantToSignInWriteAMail),
          ),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: AppLocalizations.of(context).bySigningInYouAgreeToOur(
                  AppLocalizations.of(context).privacyPolicy,
                ).split(AppLocalizations.of(context).privacyPolicy).first,
              ),
              TextSpan(
                text: AppLocalizations.of(context).privacyPolicy,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => launchUrlString('https://bikecontrol.app/privacy-policy'),
              ),
              TextSpan(
                text: AppLocalizations.of(context).bySigningInYouAgreeToOur(
                  AppLocalizations.of(context).privacyPolicy,
                ).split(AppLocalizations.of(context).privacyPolicy).last,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ).small.muted,
        if (kDebugMode && Platform.isWindows)
          Button.secondary(
            child: const Text('Register protocol handler'),
            onPressed: () {
              WindowsProtocolHandler().register('bikecontrol');
            },
          ),
      ],
    );
  }

  Widget _buildSignedIn(BuildContext context, dynamic session) {
    return Column(
      spacing: 16,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Column(
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_circle, size: 28, color: Colors.green),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    session.user.email ?? session.user.id,
                  ).small.bold,
                ],
              ),
              Button.secondary(
                child: Text(AppLocalizations.of(context).logout),
                onPressed: () async {
                  await core.api?.auth?.signOut();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _signInWithGithub() async {
    await core.api?.auth?.signInWithOAuth(
      'github',
      redirectTo: kIsWeb ? null : 'bikecontrol://login/',
      authScreenLaunchMode: kIsWeb ? null : 'externalApplication',
    );
  }

  Future<void> _signInWithFacebook() async {
    await core.api?.auth?.signInWithOAuth(
      'facebook',
      redirectTo: kIsWeb ? null : 'bikecontrol://login/',
      authScreenLaunchMode: kIsWeb ? null : 'externalApplication',
    );
  }

  Future<void> _openMailFallback() async {
    final isFromStore = (Platform.isAndroid ? isFromPlayStore == true : Platform.isIOS);
    final suffix = isFromStore ? '' : '-sw';
    final email = Uri.encodeComponent('jonas$suffix@bikecontrol.app');
    final subject = Uri.encodeComponent(
      context.i18n.helpRequested(packageInfoValue?.version ?? ''),
    );
    final dbg = await debugText();
    final body = Uri.encodeComponent('\n\n$dbg');
    final mail = Uri.parse('mailto:$email?subject=$subject&body=$body');
    await launchUrl(mail);
  }

  Widget _buildNonCommercialStub(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            spacing: 32,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Column(
                spacing: 8,
                children: [
                  Text('All features unlocked').xLarge.bold,
                  Text('Free forever').large.muted,
                ],
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Icon(Icons.check_circle, size: 48, color: Colors.green),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
