import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/router/go_router/helper/active_breakpoint_notifier.dart';
import 'package:hiddify/core/theme/app_theme.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hiddify/features/profile/widget/profile_tile.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/active/ip_widget.dart';
import 'package:hiddify/features/stats/notifier/stats_notifier.dart';
import 'package:hiddify/gen/fonts.gen.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hiddify/utils/number_formatters.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// "spriteNet" wordmark with the version pill, used as the home app bar title.
class SpriteNetWordmark extends ConsumerWidget {
  const SpriteNetWordmark({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final version = ref.watch(appInfoProvider).valueOrNull?.shortVersion ?? "";
    const style = TextStyle(fontFamily: FontFamily.russoOne, fontSize: 22, letterSpacing: .4);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: t.common.appTitle,
          excludeSemantics: true,
          child: const Text.rich(
            TextSpan(
              children: [
                TextSpan(text: "sprite", style: TextStyle(color: SpriteNetColors.textPrimary)),
                TextSpan(text: "Net", style: TextStyle(color: SpriteNetColors.lime)),
              ],
            ),
            style: style,
          ),
        ),
        if (version.isNotEmpty) ...[
          const Gap(8),
          Semantics(
            label: t.common.version,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: SpriteNetColors.lime.withValues(alpha: .5)),
              ),
              child: Text(
                "v$version",
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontSize: 11, color: SpriteNetColors.lime, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Small square outlined icon button used in the home app bar.
class HomeOutlinedIconButton extends StatelessWidget {
  const HomeOutlinedIconButton({super.key, required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: SpriteNetColors.lime),
      style: IconButton.styleFrom(
        backgroundColor: SpriteNetColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: SpriteNetColors.outline),
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration({Color border = SpriteNetColors.outline}) => BoxDecoration(
  color: SpriteNetColors.surface,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: border),
);

/// Active subscription: name, traffic bar and days left. Tapping opens the profile list,
/// the refresh button re-downloads the subscription.
class HomeSubscriptionCard extends ConsumerWidget {
  const HomeSubscriptionCard({super.key, required this.profile});

  final ProfileEntity profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final subInfo = switch (profile) {
      RemoteProfileEntity(:final subInfo) => subInfo,
      _ => null,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: _cardDecoration(),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              if (Breakpoint(context).isMobile()) {
                ref.read(bottomSheetsNotifierProvider.notifier).showProfilesOverview();
              } else {
                context.goNamed('profiles');
              }
            },
            child: Semantics(
              button: true,
              label: t.pages.profiles.viewAllProfiles,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: SpriteNetColors.lime.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(FluentIcons.key_24_regular, color: SpriteNetColors.lime, size: 20),
                        ),
                        const Gap(12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.pages.home.subscription.toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: SpriteNetColors.textSecondary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                profile.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        if (profile case final RemoteProfileEntity remote) _RefreshButton(remote),
                        const Icon(Icons.unfold_more_rounded, color: SpriteNetColors.textSecondary),
                        const Gap(4),
                      ],
                    ),
                    if (subInfo != null) ...[
                      const Gap(12),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: subInfo.ratio,
                            minHeight: 6,
                            backgroundColor: SpriteNetColors.surfaceHigh,
                            color: subInfo.ratio >= .9 ? SpriteNetColors.alert : SpriteNetColors.lime,
                          ),
                        ),
                      ),
                      const Gap(8),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: ProfileSubscriptionInfo(subInfo),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RefreshButton extends ConsumerWidget {
  const _RefreshButton(this.profile);

  final RemoteProfileEntity profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final updating = ref.watch(updateProfileNotifierProvider(profile.id)).isLoading;
    return IconButton(
      tooltip: t.pages.profiles.update,
      onPressed: updating
          ? null
          : () => ref.read(updateProfileNotifierProvider(profile.id).notifier).updateProfile(profile),
      icon: updating
          ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.sync_rounded, color: SpriteNetColors.lime),
    );
  }
}

/// Ping, download and upload tiles under the power button. Values show a dash while disconnected.
class HomeStatTiles extends ConsumerWidget with InfraLogger {
  HomeStatTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final connected = ref.watch(connectionNotifierProvider.select((value) => value.valueOrNull is Connected));
    final stats = connected ? ref.watch(statsNotifierProvider).asData?.value : null;
    final proxy = connected ? ref.watch(activeProxyNotifierProvider).asData?.value : null;

    final delay = proxy?.urlTestDelay ?? 0;
    final String ping;
    Color? pingColor;
    if (!connected) {
      ping = "—";
    } else if (delay > 65000) {
      ping = t.common.timeout;
      pingColor = SpriteNetColors.alert;
    } else if (delay > 0) {
      ping = "$delay ms";
    } else {
      ping = "…";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatTile(
              icon: FluentIcons.cellular_data_1_20_regular,
              label: t.pages.home.ping,
              value: ping,
              valueColor: pingColor,
              onTap: connected
                  ? () async {
                      try {
                        await ref.read(activeProxyNotifierProvider.notifier).urlTest("");
                      } catch (e) {
                        loggy.error("Error during URL test: $e");
                      }
                    }
                  : null,
            ),
          ),
          const Gap(8),
          Expanded(
            child: _StatTile(
              icon: FluentIcons.arrow_download_20_regular,
              label: t.components.stats.downlink,
              value: stats == null ? "—" : stats.downlink.toInt().speed(),
            ),
          ),
          const Gap(8),
          Expanded(
            child: _StatTile(
              icon: FluentIcons.arrow_upload_20_regular,
              label: t.components.stats.uplink,
              value: stats == null ? "—" : stats.uplink.toInt().speed(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.label, required this.value, this.valueColor, this.onTap});

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: _cardDecoration(),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Semantics(
            label: label,
            value: value,
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 14, color: SpriteNetColors.lime),
                      const Gap(4),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            label.toUpperCase(),
                            maxLines: 1,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: SpriteNetColors.textSecondary,
                              letterSpacing: .6,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: valueColor ?? SpriteNetColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Selected server while connected: flag, name, IP and protocol. Tap opens the server list,
/// the flag shows the server details.
class HomeServerCard extends ConsumerWidget with InfraLogger {
  HomeServerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connected = ref.watch(connectionNotifierProvider.select((value) => value.valueOrNull is Connected));
    final activeProxy = ref.watch(activeProxyNotifierProvider.select((value) => value.valueOrNull));
    final t = ref.watch(translationsProvider).requireValue;
    if (!connected || activeProxy == null) return const SizedBox.shrink();

    final theme = Theme.of(context);

    Future<void> handleUrlTest() async {
      try {
        await ref.read(activeProxyNotifierProvider.notifier).urlTest("");
      } catch (e) {
        loggy.error("Error during URL test: $e");
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: _cardDecoration(border: SpriteNetColors.lime.withValues(alpha: .35)),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => context.goNamed('proxies'),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      await handleUrlTest();
                      await ref.read(dialogNotifierProvider.notifier).showProxyInfo(outboundInfo: activeProxy);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: SpriteNetColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IPCountryFlag(
                        countryCode: activeProxy.ipinfo.countryCode,
                        organization: activeProxy.ipinfo.org,
                        size: 32,
                      ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              t.pages.home.server.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: SpriteNetColors.textSecondary,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const Gap(8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: SpriteNetColors.lime.withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                activeProxy.type,
                                style: theme.textTheme.labelSmall?.copyWith(color: SpriteNetColors.lime),
                              ),
                            ),
                          ],
                        ),
                        Semantics(
                          label: t.pages.proxies.activeProxy,
                          child: Text(
                            activeProxy.tagDisplay,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (activeProxy.ipinfo.ip.isNotEmpty)
                          IPText(ip: activeProxy.ipinfo.ip, onLongPress: handleUrlTest, constrained: true)
                        else
                          UnknownIPText(text: t.pages.proxies.unknownIp, onTap: handleUrlTest),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: SpriteNetColors.lime),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
