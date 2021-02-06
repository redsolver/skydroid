import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:preferences/preference_title.dart';
import 'package:preferences/preferences.dart';
import 'package:preferences/radio_preference.dart';
import 'package:skydroid/app.dart';
import 'package:skydroid/theme.dart';
import 'package:package_info/package_info.dart';
import 'package:system_info/system_info.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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
              final deviceInfo = DeviceInfoPlugin();
              AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

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
