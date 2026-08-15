import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wake/services/alarm_permissions.dart';
import 'package:wake/services/alarm_scheduler.dart';


class PermissionBanner extends StatefulWidget {
  const PermissionBanner({super.key});

  @override
  State<PermissionBanner> createState() => _PermissionBannerState();
}

class _PermissionBannerState extends State<PermissionBanner>
    with WidgetsBindingObserver {
  AlarmPermissions _permissions = AlarmPermissions.unknown;
  bool _needsOemSetup = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final permissions = await AlarmScheduler.permissionStatus();
    final oem = await AlarmScheduler.needsOemSetup();
    if (mounted) {
      setState(() {
        _permissions = permissions;
        _needsOemSetup = oem;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final missing = _permissions.missing;
    if (missing.isEmpty && !_needsOemSetup) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Alarms can be skipped',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
            for (final permission in missing)
              _PermissionRow(
                title: permission.title,
                rationale: permission.rationale,
                onGrant: () => AlarmScheduler.requestPermission(permission),
              ),
            if (_needsOemSetup)
              _PermissionRow(
                title: 'Extra device settings',
                rationale:
                    'This phone also needs "Display pop-up windows while '
                    'running in the background" and "Show on Lock screen".',
                onGrant: AlarmScheduler.openOemSettings,
                action: 'Open',
              ),
          ],
        ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.title,
    required this.rationale,
    required this.onGrant,
    this.action = 'Allow',
  });

  final String title;
  final String rationale;
  final VoidCallback onGrant;
  final String action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                Text(
                  rationale,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer.withValues(
                      alpha: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onGrant, child: Text(action)),
        ],
      ),
    );
  }
}
