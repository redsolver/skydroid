import 'package:flutter/material.dart';
import 'package:preferences/preference_title.dart';
import 'package:preferences/preferences.dart';
import 'package:preferences/radio_preference.dart';
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
          PreferenceTitle('App Theme'),
          RadioPreference(
            'Light',
            'light',
            'theme',
            onSelect: () {
              AppTheme.of(context).setTheme(
                'light',
              );
            },
          ),
          RadioPreference(
            'Sepia',
            'sepia',
            'theme',
            onSelect: () {
              AppTheme.of(context).setTheme(
                'sepia',
              );
            },
          ),
          RadioPreference(
            'Dark',
            'dark',
            'theme',
            onSelect: () {
              AppTheme.of(context).setTheme(
                'dark',
              );
            },
          ),
          RadioPreference(
            'Black',
            'black',
            'theme',
            onSelect: () {
              AppTheme.of(context).setTheme(
                'black',
              );
            },
          ),
          PreferenceTitle('Services'),
          TextFieldPreference('Multi-DoH Server', 'dnsUrl'),
          TextFieldPreference('Skynet Portal', 'skynetPortal'),
          PreferenceTitle('About'),
          ListTile(
            title: Text(
              'Show licenses',
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
