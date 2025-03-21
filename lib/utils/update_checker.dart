import 'package:flutter/material.dart';
import 'package:foodkie_express/utils/remote_config_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateChecker {
  final BuildContext? context;

  UpdateChecker(this.context);

  Future<void> checkForUpdates() async {
    final remoteConfigManager = RemoteConfigManager();
    await remoteConfigManager.initialize();

    final latestVersion = remoteConfigManager.getLatestVersion();
    final currentVersion = (await PackageInfo.fromPlatform()).version;

    if (latestVersion.compareTo(currentVersion) > 0) {
      _showUpdateDialog(remoteConfigManager.getShouldUpdate(), latestVersion);
    } else {}
  }

  Future<void> _showUpdateDialog(bool update, String newVersion) async {
    final packageInfo = (await PackageInfo.fromPlatform());
    showDialog(
      context: context!,
      barrierDismissible: !update,
      builder:
          (context) => AlertDialog(
            actionsAlignment: MainAxisAlignment.end,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12.0)),
            ),
            actionsPadding: const EdgeInsets.only(right: 12, bottom: 10),
            title: const Text('Hey a new update is ready for you!'),
            content: Text(
              "Don't miss out on the new ${packageInfo.appName} goodness! Update to $newVersion.",
            ),
            actions: <Widget>[
              if (!update)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Later'),
                ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Download Foodkie Express From Play Store"),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // launchUrl(
                  //   Uri.parse(
                  //       "https://play.google.com/store/apps/details?id=com.infinite.ballsort.ball_sort_challenge"),
                  //   mode: LaunchMode.externalApplication,
                  // );
                },
                child: const Text('Update Now'),
              ),
            ],
          ),
    );
  }
}
