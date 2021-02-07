import 'package:device_apps/device_apps.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:preferences/preference_title.dart';
import 'package:preferences/preferences.dart';
import 'package:preferences/radio_preference.dart';
import 'package:skydroid/app.dart';
import 'package:skydroid/page/widget/install.dart';
import 'package:skydroid/theme.dart';
import 'package:package_info/package_info.dart';
import 'package:system_info/system_info.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    if (androidInfo.version.sdkInt >= 24) {
      // _isShizukuInstalled = false;
      _startShizukuCheckLoop();
    }

    super.initState();
  }

  bool _isShizukuInstalled;

  final shizukuPackageName = 'moe.shizuku.privileged.api';

  _startShizukuCheckLoop() async {
    // if (androidInfo.version.sdkInt < 24) return;

    while (true) {
      final a = await DeviceApps.getApp(shizukuPackageName);
      if (!mounted) break;

      final isInstalled = a != null;

      if (isInstalled != _isShizukuInstalled) {
        setState(() {
          _isShizukuInstalled = isInstalled;
        });
      }

      await Future.delayed(Duration(seconds: 1));
    }
  }

  void _checkForPermissionLoop() async {
    while (true) {
      final bool permissionGranted =
          await platform.invokeMethod('checkShizukuPermission');

      if (!mounted) break;

      if (permissionGranted) {
        setState(() {
          PrefService.setBool('use_shizuku', true);
        });
        break;
      }

      await Future.delayed(Duration(milliseconds: 100));
    }
  }

  void _switchShizukuToggle(bool val) {
    if (val) {
      setState(() {
        PrefService.setBool('use_shizuku', false);
      });
      _checkForPermissionLoop();
      platform.invokeMethod('requestShizukuPermission');
    } else {
      setState(() {
        PrefService.setBool('use_shizuku', false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context)
          .copyWith(primaryColor: Theme.of(context).accentColor),
      child: ListView(
        children: <Widget>[
          PreferenceTitle(
            tr.settingsPageAppThemeTitle,
          ),
          RadioPreference(
            tr.settingsPageAppThemeOptionLight,
            'light',
            'theme',
            onSelect: () {
              AppTheme.of(context).setTheme(
                'light',
              );
            },
          ),
          RadioPreference(
            tr.settingsPageAppThemeOptionSepia,
            'sepia',
            'theme',
            onSelect: () {
              AppTheme.of(context).setTheme(
                'sepia',
              );
            },
          ),
          RadioPreference(
            tr.settingsPageAppThemeOptionDark,
            'dark',
            'theme',
            onSelect: () {
              AppTheme.of(context).setTheme(
                'dark',
              );
            },
          ),
          RadioPreference(
            tr.settingsPageAppThemeOptionBlack,
            'black',
            'theme',
            onSelect: () {
              AppTheme.of(context).setTheme(
                'black',
              );
            },
          ),
          PreferenceTitle(tr.settingsPageServicesTitle),
          TextFieldPreference(tr.settingsPageServicesMultiDoHServer, 'dnsUrl'),
          TextFieldPreference(
              tr.settingsPageServicesSkynetPortal, 'skynetPortal'),
          if (_isShizukuInstalled != null) ...[
            PreferenceTitle(
              tr.settingsPageShizukuTitle,
            ),
            PreferenceText(
              tr.settingsPageShizukuDescription,
              overflow: TextOverflow.visible,
            ),
            _isShizukuInstalled
                ? ListTile(
                    title: Text(tr.settingsPageShizukuToggleSwitch),
                    trailing: Switch(
                      value: PrefService.getBool('use_shizuku') ?? false,
                      onChanged: (val) {
                        _switchShizukuToggle(val);
                      },
                    ),
                    onTap: () {
                      _switchShizukuToggle(
                          !(PrefService.getBool('use_shizuku') ?? false));
                    },
                  )
                : Center(
                    child: RaisedButton(
                      onPressed: () {
                        launch(
                            'https://to.skydroid.app/moe.shizuku.privileged.api.bdroid');
                      },
                      child: Text(tr.settingsPageShizukuInstallButton),
                    ),
                  ),
          ],
          PreferenceTitle(tr.settingsPageAboutTitle),
          ListTile(
            title: Text(
              tr.settingsPageAboutShowLicenses,
            ),
            onTap: () async {
              final packageInfo = await PackageInfo.fromPlatform();

              showAboutDialog(
                applicationName: packageInfo.appName,
                applicationVersion: 'Version ${packageInfo.version}',
                applicationLegalese: 'GNU GENERAL PUBLIC LICENSE v3',
                applicationIcon: SizedBox(
                  height: 64,
                  width: 64,
                  child: Image.asset('assets/icon/icon.png'),
                ),
                context: context,
              );
            },
          ),
          ListTile(
            title: Text(
              tr.settingsPageAboutDebug,
            ),
            onTap: () async {
              final packageInfo = await PackageInfo.fromPlatform();

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(tr.settingsPageAboutDebug),
                  content: Text(
                    [
                      'App Version ${packageInfo.version} (${packageInfo.buildNumber})',
                      'Supported ABIs: ${androidInfo.supportedAbis}',
                      'Android version: ${androidInfo.version.release}',
                      'Android sdkVersion: ${androidInfo.version.sdkInt}',
                      'Security patch: ${androidInfo.version.securityPatch}',
                      'Brand: ${androidInfo.brand}',
                      'Manufacturer: ${androidInfo.manufacturer}',
                      'Device: ${androidInfo.device}',
                      'Model: ${androidInfo.model}',
                      'Product: ${androidInfo.product}',
                      'isPhysicalDevice: ${androidInfo.isPhysicalDevice}',
                      'kernelArchitecture: ${SysInfo.kernelArchitecture}',
                      'kernelBitness: ${SysInfo.kernelBitness}',
                      'userSpaceBitness: ${SysInfo.userSpaceBitness}',
                    ].join('\n'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: Navigator.of(context).pop,
                      child: Text(tr.settingsPageAboutDebugDialogClose),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
