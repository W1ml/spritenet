import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/core/theme/app_theme.dart';
import 'package:hiddify/features/home/widget/home_cards.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/utils/uri_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Slim quick settings pill at the bottom of the home screen, shown once a profile exists.
class HomeBottomActions extends ConsumerWidget {
  const HomeBottomActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final hasProfile = ref.watch(hasAnyProfileProvider).value ?? false;
    if (!hasProfile) return const Gap(16);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: OutlinedButton.icon(
        key: const ValueKey("home_quick_settings"),
        onPressed: () => ref.read(bottomSheetsNotifierProvider.notifier).showQuickSettings(),
        style: OutlinedButton.styleFrom(
          foregroundColor: SpriteNetColors.textPrimary,
          backgroundColor: SpriteNetColors.surface.withValues(alpha: .8),
          side: const BorderSide(color: SpriteNetColors.outline),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        ),
        icon: const Icon(FluentIcons.options_20_regular, size: 18, color: SpriteNetColors.lime),
        label: Text(t.pages.home.quickSettings),
      ),
    );
  }
}

/// Telegram bot shortcut (keys, billing, support) in the home app bar.
class TelegramSupportButton extends ConsumerWidget {
  const TelegramSupportButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    return Semantics(
      label: t.pages.home.support,
      button: true,
      child: HomeOutlinedIconButton(
        key: const ValueKey("home_telegram_support"),
        icon: FontAwesomeIcons.telegram,
        tooltip: "${t.pages.home.support}: ${t.pages.home.supportHint}",
        onPressed: () => UriUtils.tryLaunch(Uri.parse(Constants.telegramBotUrl)),
      ),
    );
  }
}
