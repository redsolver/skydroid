import 'package:flutter/material.dart';
import 'package:preferences/preference_title.dart';
import 'package:preferences/preferences.dart';
import 'package:preferences/radio_preference.dart';
import 'package:skydroid/app.dart';
import 'package:skydroid/theme.dart';
import 'package:package_info/package_info.dart';

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
        ],
      ),
    );
  }
}
