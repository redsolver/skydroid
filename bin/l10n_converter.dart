import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

void main(List<String> args) {
  const assetsDirectory = 'assets';

  for (final File file
      in Directory(join(assetsDirectory, 'translations')).listSync()) {
    final locale = file.path.split('/').last.split('.').first;

    // ignore: avoid_print
    print('Converting locale $locale...');

    final map = <String, dynamic>{
      '@@locale': locale,
    };

    final data =
        (loadYaml(file.readAsStringSync()) as Map).cast<String, String>();

    for (final key in data.keys) {
      map[key] = data[key];
      final metaMap = <String, dynamic>{};

      final matches = RegExp(r'(?<={)\w+(?=})').allMatches(data[key]);

      if (matches.isNotEmpty) {
        metaMap['placeholders'] = {};

        for (final match in matches) {
          metaMap['placeholders'][match.group(0)] = {};
        }
      }

      map['@$key'] = metaMap;
    }

    File(join(assetsDirectory, 'l10n', 'app_$locale.arb'))
      ..createSync(recursive: true)
      ..writeAsStringSync(json.encode(map));
  }
}
