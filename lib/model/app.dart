import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:skydroid/app.dart';

part 'app.g.dart';

@HiveType(typeId: 1)
@JsonSerializable(anyMap: true)
class App {
  @HiveField(1)
  List<String> categories;
  @HiveField(2)
  String license;
  @HiveField(3)
  String authorName;
  @HiveField(4)
  String authorEmail;
  @HiveField(5)
  String sourceCode;
  @HiveField(6)
  String issueTracker;
  @HiveField(7)
  String changelog;
  @HiveField(8)
  String name;
  @HiveField(9)
  String packageName;

  @HiveField(20)
  Map<String, Map> localized;

  String get localizedName => getLocalizedStringWithCache('name', name);

  String get localizedSummary =>
      getLocalizedStringWithCache('summary', summary);

  String get localizedDescription =>
      getLocalizedStringWithCache('description', description);
  String get localizedWhatsNew =>
      getLocalizedStringWithCache('whatsNew', whatsNew);

  //String get localizedIcon => getLocalizedString('icon', icon);
  String get localizedVideo => getLocalizedStringWithCache('video', null);

  final localizedCache = <String, String>{};

  List<String> localizedPhoneScreenshotsCache;

  String getLocalizedStringWithCache(String key, String nonLocalizedValue) {
    if (localizedCache.containsKey(key)) return localizedCache[key];

    final value = getLocalizedString(key, nonLocalizedValue);

    localizedCache[key] = value;
    return value;
  }

  String getLocalizedString(String key, String nonLocalizedValue) {
    if (localized != null) {
      for (var loc in languagePreferences) {
        var entry = localized[loc];

        if (entry == null) continue;

        if (entry.containsKey(key)) {
          return entry[key];
        }
      }
    }

    return nonLocalizedValue ??
        ((localized ?? {})['en'] ?? {})[key] ??
        ((localized ?? {})['en-US'] ?? {})[key];
  }

  List<String> get localizedPhoneScreenshots {
    if (localized == null) return [];

    if (localizedPhoneScreenshotsCache != null)
      return localizedPhoneScreenshotsCache;

    localizedPhoneScreenshotsCache = getLocalizedPhoneScreenshots();
    return localizedPhoneScreenshotsCache;
  }

  List<String> getLocalizedPhoneScreenshots() {
    String usedLocale;

    for (var loc in languagePreferences) {
      var entry = localized[loc];

      if (entry == null) continue;

      if (entry.containsKey('phoneScreenshots')) {
        usedLocale = loc;
        break;
      }
    }
    if (usedLocale == null) {
      if (localized.containsKey('en') &&
          localized['en'].containsKey('phoneScreenshots')) {
        usedLocale = 'en';
      } else if (localized.containsKey('en-US') &&
          localized['en-US'].containsKey('phoneScreenshots')) {
        usedLocale = 'en-US';
      } else {
        return null;
      }
    }

    List screenshots = localized[usedLocale]['phoneScreenshots'];
    if (localized[usedLocale].containsKey('phoneScreenshotsBaseUrl')) {
      screenshots = screenshots
          .map((s) => localized[usedLocale]['phoneScreenshotsBaseUrl'] + s)
          .toList();
    }

    return screenshots.cast<String>();
  }

  @HiveField(30)
  String summary;

  @HiveField(31)
  String description;

  @HiveField(32)
  String whatsNew;

  @HiveField(22)
  String icon;

  @HiveField(11)
  List<Build> builds;
  @HiveField(12)
  String currentVersionName;
  @HiveField(13)
  int currentVersionCode;

  @HiveField(14)
  int added;
  @HiveField(15)
  int lastUpdated;

  @HiveField(16)
  String webSite;
  @HiveField(17)
  String translation;
  @HiveField(24)
  List<String> antiFeatures;

  @HiveField(18)
  String donate;
  @HiveField(19)
  String bitcoin;
  @HiveField(25)
  String litecoin;
  @HiveField(26)
  String liberapay;
  @HiveField(28)
  String openCollective;

  @HiveField(29)
  String requirements;

  @HiveField(250)
  String metadataSrcHash;

  App();

  factory App.fromJson(Map<dynamic, dynamic> json) => _$AppFromJson(json);

  Map<String, dynamic> toJson() => _$AppToJson(this);
}

@HiveType(typeId: 3)
@JsonSerializable(anyMap: true)
class Build {
  @HiveField(1)
  String versionName;
  @HiveField(2)
  int versionCode;
  @HiveField(3)
  String sha256;
  @HiveField(4)
  String apkLink;

  @HiveField(11)
  Map<String, ABISpecificBuild> abis;

  // TODO Show some more of this info on the app page

  @HiveField(5)
  int size; // optional
/*   @HiveField(6)
  int sdkver; // optional
  @HiveField(7)
  int maxsdkver; // optional */
  @HiveField(7)
  int minSdkVersion; // optional
  @HiveField(8)
  int targetSdkVersion; // optional

  @HiveField(9)
  int added; // optional

  @HiveField(10)
  List<String> permissions;
/*   @HiveField(11)
  List<String> nativecode; */

  Build();

  factory Build.fromJson(Map<dynamic, dynamic> json) => _$BuildFromJson(json);

  Map<String, dynamic> toJson() => _$BuildToJson(this);
}

@HiveType(typeId: 6)
@JsonSerializable(anyMap: true)
class ABISpecificBuild {
  @HiveField(1)
  String apkLink;
  @HiveField(2)
  String sha256;

  ABISpecificBuild();

  factory ABISpecificBuild.fromJson(Map<dynamic, dynamic> json) =>
      _$ABISpecificBuildFromJson(json);

  Map<String, dynamic> toJson() => _$ABISpecificBuildToJson(this);
}
