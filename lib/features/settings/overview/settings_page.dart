import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/router/go_router/helper/active_breakpoint_notifier.dart';
import 'package:hiddify/core/theme/app_theme.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/settings/notifier/config_option/config_option_notifier.dart';
import 'package:hiddify/features/settings/notifier/reset_tunnel/reset_tunnel_notifier.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum ConfigOptionSection {
  warp,
  fragment;

  static final _warpKey = GlobalKey(debugLabel: "warp-section-key");
  static final _fragmentKey = GlobalKey(debugLabel: "fragment-section-key");

  GlobalKey get key => switch (this) {
    ConfigOptionSection.warp => _warpKey,
    ConfigOptionSection.fragment => _fragmentKey,
  };
}

class SettingsPage extends HookConsumerWidget {
  SettingsPage({super.key, String? section})
    : section = section != null ? ConfigOptionSection.values.byName(section) : null;

  final ConfigOptionSection? section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    // final scrollController = useScrollController();

    // useMemoized(
    //   () {
    //     if (section != null) {
    //       WidgetsBinding.instance.addPostFrameCallback(
    //         (_) {
    //           final box = section!.key.currentContext?.findRenderObject() as RenderBox?;

    //           final offset = box?.localToGlobal(Offset.zero);
    //           if (offset == null) return;
    //           final height = scrollController.offset + offset.dy - MediaQueryData.fromView(View.of(context)).padding.top - kToolbarHeight;
    //           scrollController.animateTo(
    //             height,
    //             duration: const Duration(milliseconds: 500),
    //             curve: Curves.decelerate,
    //           );
    //         },
    //       );
    //     }
    //   },
    // );

    return Scaffold(
      appBar: AppBar(
        title: Text(t.pages.settings.title),
        actions: [
          MenuAnchor(
            menuChildren: <Widget>[
              SubmenuButton(
                menuChildren: <Widget>[
                  MenuItemButton(
                    onPressed: () async => await ref
                        .read(dialogNotifierProvider.notifier)
                        .showConfirmation(
                          title: t.common.msg.import.confirm,
                          message: t.dialogs.confirmation.settings.import.msg,
                        )
                        .then((shouldImport) async {
                          if (shouldImport) {
                            await ref.read(configOptionNotifierProvider.notifier).importFromClipboard();
                          }
                        }),
                    child: Text(t.pages.settings.options.import.clipboard),
                  ),
                  MenuItemButton(
                    onPressed: () async => await ref
                        .read(dialogNotifierProvider.notifier)
                        .showConfirmation(
                          title: t.common.msg.import.confirm,
                          message: t.dialogs.confirmation.settings.import.msg,
                        )
                        .then((shouldImport) async {
                          if (shouldImport) {
                            await ref.read(configOptionNotifierProvider.notifier).importFromJsonFile();
                          }
                        }),
                    child: Text(t.pages.settings.options.import.file),
                  ),
                ],
                child: Text(t.common.import),
              ),
              SubmenuButton(
                menuChildren: <Widget>[
                  MenuItemButton(
                    onPressed: () async => await ref.read(configOptionNotifierProvider.notifier).exportJsonClipboard(),
                    child: Text(t.pages.settings.options.export.anonymousToClipboard),
                  ),
                  MenuItemButton(
                    onPressed: () async => await ref.read(configOptionNotifierProvider.notifier).exportJsonFile(),
                    child: Text(t.pages.settings.options.export.anonymousToFile),
                  ),
                  const PopupMenuDivider(),
                  MenuItemButton(
                    onPressed: () async => await ref
                        .read(configOptionNotifierProvider.notifier)
                        .exportJsonClipboard(excludePrivate: false),
                    child: Text(t.pages.settings.options.export.allToClipboard),
                  ),
                  MenuItemButton(
                    onPressed: () async =>
                        await ref.read(configOptionNotifierProvider.notifier).exportJsonFile(excludePrivate: false),
                    child: Text(t.pages.settings.options.export.allToFile),
                  ),
                ],
                child: Text(t.common.export),
              ),
              const PopupMenuDivider(),
              MenuItemButton(
                child: Text(t.pages.settings.options.reset),
                onPressed: () async => await ref.read(configOptionNotifierProvider.notifier).resetOption(),
              ),
            ],
            builder: (context, controller, child) => IconButton(
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              icon: const Icon(Icons.more_vert_rounded),
            ),
          ),
          const Gap(8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _SettingsGroup(
            title: t.pages.settings.connectionGroup,
            children: [
              SettingsSection(
                title: t.pages.settings.routing.title,
                icon: Icons.route_rounded,
                subtitle: Text(t.pages.settings.routingHint),
                namedLocation: context.namedLocation('routingOptions'),
              ),
              SettingsSection(
                title: t.pages.settings.dns.title,
                icon: Icons.dns_rounded,
                subtitle: Text(t.pages.settings.dnsHint),
                namedLocation: context.namedLocation('dnsOptions'),
              ),
              if (ref.watch(hasAnyProfileProvider).value ?? false)
                SettingsSection(
                  title: t.pages.settings.chain.title,
                  icon: Icons.webhook_rounded,
                  subtitle: Text(t.pages.settings.chain.subtitle),
                  namedLocation: context.namedLocation('chainOptions'),
                ),
              // SpriteNet: inbound, TLS tricks and WARP sections are hidden to keep the app simple for end users.
              // Their routes still exist, so they can be brought back by re-adding the sections here.
              if (PlatformUtils.isIOS)
                _SettingsItem(
                  title: t.pages.settings.resetTunnel,
                  icon: Icons.autorenew_rounded,
                  onTap: () async {
                    await ref.read(resetTunnelNotifierProvider.notifier).run();
                  },
                ),
            ],
          ),
          const Gap(20),
          _SettingsGroup(
            title: t.pages.settings.appGroup,
            children: [
              SettingsSection(
                title: t.pages.settings.general.title,
                icon: Icons.tune_rounded,
                subtitle: Text(t.pages.settings.generalHint),
                namedLocation: context.namedLocation('general'),
              ),
              // SpriteNet: the system logs page is not shown to end users.
              if (Breakpoint(context).isMobile())
                SettingsSection(
                  title: t.pages.about.title,
                  icon: Icons.info_outline_rounded,
                  subtitle: Text(t.pages.settings.aboutHint),
                  namedLocation: context.namedLocation('about'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Titled card that groups settings items, separated by thin dividers.
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 12,
                decoration: BoxDecoration(color: SpriteNetColors.lime, borderRadius: BorderRadius.circular(2)),
              ),
              const Gap(8),
              Text(
                title.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(color: SpriteNetColors.textSecondary, letterSpacing: 1.4),
              ),
            ],
          ),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: SpriteNetColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SpriteNetColors.outline),
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                for (final (i, child) in children.indexed) ...[
                  if (i > 0) const Divider(height: 1, indent: 64, endIndent: 16),
                  child,
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Settings row: icon in a tinted rounded square, title, optional hint and a lime chevron.
class _SettingsItem extends StatelessWidget {
  const _SettingsItem({required this.title, required this.icon, this.subtitle, required this.onTap});

  final String title;
  final Widget? subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: SpriteNetColors.lime.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 20, color: SpriteNetColors.lime),
            ),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  if (subtitle != null)
                    DefaultTextStyle.merge(
                      style: theme.textTheme.bodySmall?.copyWith(color: SpriteNetColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      child: subtitle!,
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: SpriteNetColors.lime),
          ],
        ),
      ),
    );
  }
}

class SettingsSection extends HookConsumerWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    required this.namedLocation,
  });

  final String title;
  final Widget? subtitle;
  final IconData icon;
  final String namedLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SettingsItem(title: title, icon: icon, subtitle: subtitle, onTap: () => context.go(namedLocation));
  }
}
