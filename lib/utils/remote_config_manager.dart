import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigManager {
static final RemoteConfigManager _instance = RemoteConfigManager._internal();factory RemoteConfigManager() => _instance;

RemoteConfigManager._internal();

final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

Future<void> initialize() async {
  await _remoteConfig.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: const Duration(seconds: 10),
    minimumFetchInterval: const Duration(hours: 1),
  ));
  await _remoteConfig.fetchAndActivate();
}

String getLatestVersion() {
  return _remoteConfig.getString('new_version');
}

bool getShouldUpdate() {
  return _remoteConfig.getBool('should_update');
}
}