import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:in_app_update/in_app_update.dart';

/// Forces the latest Play Store build: whenever an update is available the
/// native full-screen (immediate) update flow is shown, and it is shown again
/// every time the app returns to the foreground until the user is updated.
/// Android only; any failure (sideloaded/debug builds, no Play Store) is ignored
/// so it never affects the rest of the app.
class AppUpdateService with WidgetsBindingObserver {
  AppUpdateService._();

  static final AppUpdateService _instance = AppUpdateService._();
  static bool _started = false;
  static bool _inProgress = false;

  static void start() {
    if (_started || !Platform.isAndroid) return;
    _started = true;
    WidgetsBinding.instance.addObserver(_instance);
    checkForUpdate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) checkForUpdate();
  }

  static Future<void> checkForUpdate() async {
    if (_inProgress || !Platform.isAndroid) return;
    _inProgress = true;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability ==
          UpdateAvailability.developerTriggeredUpdateInProgress) {
        // An immediate update was interrupted; resume it.
        await InAppUpdate.performImmediateUpdate();
      } else if (info.updateAvailability ==
          UpdateAvailability.updateAvailable) {
        if (info.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
        } else if (info.flexibleUpdateAllowed) {
          final result = await InAppUpdate.startFlexibleUpdate();
          if (result == AppUpdateResult.success) {
            await InAppUpdate.completeFlexibleUpdate();
          }
        }
      }
    } catch (e) {
      developer.log('In-app update check failed: $e', name: 'AppUpdateService');
    } finally {
      _inProgress = false;
    }
  }
}
