import 'package:bike_control/main.dart';
import 'package:bike_control/utils/iap/iap_manager.dart';
import 'package:bike_control/widgets/ui/gradient_text.dart';
import 'package:bike_control/widgets/ui/small_progress_indicator.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

PackageInfo? packageInfoValue;
bool? isFromPlayStore;

class AppTitle extends StatefulWidget {
  const AppTitle({super.key});

  @override
  State<AppTitle> createState() => _AppTitleState();
}

class _AppTitleState extends State<AppTitle> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    IAPManager.instance.entitlements.addListener(_onEntitlementsUpdate);

    if (packageInfoValue == null) {
      PackageInfo.fromPlatform().then((value) {
        setState(() {
          packageInfoValue = value;
        });
        _checkForUpdate();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForUpdate();
    }
  }

  @override
  dispose() {
    WidgetsBinding.instance.removeObserver(this);
    IAPManager.instance.entitlements.removeListener(_onEntitlementsUpdate);
    super.dispose();
  }

  void _checkForUpdate() async {
    // Update checks removed for non-commercial builds.
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GradientText(
          'BikeControl',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        if (packageInfoValue != null)
          Text(
            'v${packageInfoValue!.version} - ${IAPManager.instance.getStatusMessage()}',
            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.mutedForeground.withAlpha(200)),
          ).mono
        else
          SmallProgressIndicator(),

        if (packageInfoValue != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'No updates available',
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.mutedForeground.withAlpha(200)),
            ).mono,
          ),
      ],
    );
  }



  void _onEntitlementsUpdate() {
    setState(() {});
  }
}
