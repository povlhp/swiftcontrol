import 'package:bike_control/gen/l10n.dart';
import 'package:bike_control/services/review_prompt_service.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ReviewBanner extends StatelessWidget {
  final ReviewPromptService service;
  const ReviewBanner({super.key, required this.service});

  Future<void> _onRate() async {
    await launchUrlString(
      'https://play.google.com/store/apps/details?id=de.jonasbark.swiftcontrol',
      mode: LaunchMode.externalApplication,
    );
    await service.markCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: service.shouldShowBanner,
      builder: (context, show, _) {
        if (!show) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            filled: true,
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.star_rate, color: Color(0xFFF59E0B), size: 20),
                const Gap(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context).reviewPromptTitle).small.semiBold,
                      const Gap(4),
                      Text(AppLocalizations.of(context).reviewPromptBody).xSmall.muted,
                      const Gap(8),
                      PrimaryButton(
                        onPressed: _onRate,
                        child: Text(AppLocalizations.of(context).reviewPromptRate).small,
                      ),
                    ],
                  ),
                ),
                IconButton.ghost(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => service.dismiss(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
