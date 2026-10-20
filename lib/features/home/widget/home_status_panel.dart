import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/core/theme/app_theme.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/utils/uri_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Bottom row of the home screen: Telegram support and, once a profile exists, quick settings.
class HomeBottomActions extends ConsumerWidget {
  const HomeBottomActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final hasProfile = ref.watch(hasAnyProfileProvider).value ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          const Expanded(child: TelegramSupportButton()),
          if (hasProfile) ...[
            const Gap(8),
            Tooltip(
              message: t.pages.home.quickSettings,
              child: SizedBox.square(
                dimension: 52,
                child: IconButton(
                  key: const ValueKey("home_quick_settings"),
                  onPressed: () => ref.read(bottomSheetsNotifierProvider.notifier).showQuickSettings(),
                  icon: const Icon(FluentIcons.options_24_regular, color: SpriteNetColors.lime),
                  style: IconButton.styleFrom(
                    backgroundColor: SpriteNetColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: SpriteNetColors.outline),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shortcut to the SpriteNet Telegram bot (keys, billing, support).
class TelegramSupportButton extends ConsumerWidget {
  const TelegramSupportButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    return Tooltip(
      message: t.pages.home.supportHint,
      child: SizedBox(
        height: 52,
        child: FilledButton.icon(
          key: const ValueKey("home_telegram_support"),
          style: FilledButton.styleFrom(
            backgroundColor: SpriteNetColors.lime,
            foregroundColor: SpriteNetColors.onLime,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () => UriUtils.tryLaunch(Uri.parse(Constants.telegramBotUrl)),
          icon: const Icon(Icons.send_rounded),
          label: Text(
            t.pages.home.support.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.2),
          ),
        ),
      ),
    );
  }
}
