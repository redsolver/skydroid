// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppAdapter extends TypeAdapter<App> {
  @override
  final int typeId = 1;

  @override
  App read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return App()
      ..categories = (fields[1] as List)?.cast<String>()
      ..license = fields[2] as String
      ..authorName = fields[3] as String
      ..authorEmail = fields[4] as String
      ..sourceCode = fields[5] as String
      ..issueTracker = fields[6] as String
      ..changelog = fields[7] as String
      ..name = fields[8] as String
      ..packageName = fields[9] as String
      ..localized = (fields[20] as Map)?.map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as Map)?.cast<dynamic, dynamic>()))
      ..summary = fields[30] as String
      ..description = fields[31] as String
      ..whatsNew = fields[32] as String
      ..icon = fields[22] as String
      ..builds = (fields[11] as List)?.cast<Build>()
      ..currentVersionName = fields[12] as String
      ..currentVersionCode = fields[13] as int
      ..added = fields[14] as int
      ..lastUpdated = fields[15] as int
      ..webSite = fields[16] as String
      ..translation = fields[17] as String
      ..antiFeatures = (fields[24] as List)?.cast<String>()
      ..donate = fields[18] as String
      ..bitcoin = fields[19] as String
      ..litecoin = fields[25] as String
      ..liberapay = fields[26] as String
      ..openCollective = fields[28] as String
      ..requirements = fields[29] as String
      ..metadataSrcHash = fields[250] as String;
  }

  @override
  void write(BinaryWriter writer, App obj) {
    writer
      ..writeByte(29)
      ..writeByte(1)
      ..write(obj.categories)
      ..writeByte(2)
      ..write(obj.license)
      ..writeByte(3)
      ..write(obj.authorName)
      ..writeByte(4)
      ..write(obj.authorEmail)
      ..writeByte(5)
      ..write(obj.sourceCode)
      ..writeByte(6)
      ..write(obj.issueTracker)
      ..writeByte(7)
      ..write(obj.changelog)
      ..writeByte(8)
      ..write(obj.name)
      ..writeByte(9)
      ..write(obj.packageName)
      ..writeByte(20)
      ..write(obj.localized)
      ..writeByte(30)
      ..write(obj.summary)
      ..writeByte(31)
      ..write(obj.description)
      ..writeByte(32)
      ..write(obj.whatsNew)
      ..writeByte(22)
      ..write(obj.icon)
      ..writeByte(11)
      ..write(obj.builds)
      ..writeByte(12)
      ..write(obj.currentVersionName)
      ..writeByte(13)
      ..write(obj.currentVersionCode)
      ..writeByte(14)
      ..write(obj.added)
      ..writeByte(15)
      ..write(obj.lastUpdated)
      ..writeByte(16)
      ..write(obj.webSite)
      ..writeByte(17)
      ..write(obj.translation)
      ..writeByte(24)
      ..write(obj.antiFeatures)
      ..writeByte(18)
      ..write(obj.donate)
      ..writeByte(19)
      ..write(obj.bitcoin)
      ..writeByte(25)
      ..write(obj.litecoin)
      ..writeByte(26)
      ..write(obj.liberapay)
      ..writeByte(28)
      ..write(obj.openCollective)
      ..writeByte(29)
      ..write(obj.requirements)
      ..writeByte(250)
      ..write(obj.metadataSrcHash);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BuildAdapter extends TypeAdapter<Build> {
  @override
  final int typeId = 3;

  @override
  Build read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Build()
      ..versionName = fields[1] as String
      ..versionCode = fields[2] as int
      ..sha256 = fields[3] as String
      ..apkLink = fields[4] as String
      ..abis = (fields[11] as Map)?.cast<String, ABISpecificBuild>()
      ..size = fields[5] as int
      ..minSdkVersion = fields[7] as int
      ..targetSdkVersion = fields[8] as int
      ..added = fields[9] as int
      ..permissions = (fields[10] as List)?.cast<String>();
  }

  @override
  void write(BinaryWriter writer, Build obj) {
    writer
      ..writeByte(10)
      ..writeByte(1)
      ..write(obj.versionName)
      ..writeByte(2)
      ..write(obj.versionCode)
      ..writeByte(3)
      ..write(obj.sha256)
      ..writeByte(4)
      ..write(obj.apkLink)
      ..writeByte(11)
      ..write(obj.abis)
      ..writeByte(5)
      ..write(obj.size)
      ..writeByte(7)
      ..write(obj.minSdkVersion)
      ..writeByte(8)
      ..write(obj.targetSdkVersion)
      ..writeByte(9)
      ..write(obj.added)
      ..writeByte(10)
      ..write(obj.permissions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BuildAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ABISpecificBuildAdapter extends TypeAdapter<ABISpecificBuild> {
  @override
  final int typeId = 6;

  @override
  ABISpecificBuild read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ABISpecificBuild()
      ..apkLink = fields[1] as String
      ..sha256 = fields[2] as String;
  }

  @override
  void write(BinaryWriter writer, ABISpecificBuild obj) {
    writer
      ..writeByte(2)
      ..writeByte(1)
      ..write(obj.apkLink)
      ..writeByte(2)
      ..write(obj.sha256);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ABISpecificBuildAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

App _$AppFromJson(Map json) {
  return App()
    ..categories =
        (json['categories'] as List)?.map((e) => e as String)?.toList()
    ..license = json['license'] as String
    ..authorName = json['authorName'] as String
    ..authorEmail = json['authorEmail'] as String
    ..sourceCode = json['sourceCode'] as String
    ..issueTracker = json['issueTracker'] as String
    ..changelog = json['changelog'] as String
    ..name = json['name'] as String
    ..packageName = json['packageName'] as String
    ..localized = (json['localized'] as Map)?.map(
      (k, e) => MapEntry(k as String, e as Map),
    )
    ..localizedPhoneScreenshotsCache =
        (json['localizedPhoneScreenshotsCache'] as List)
            ?.map((e) => e as String)
            ?.toList()
    ..summary = json['summary'] as String
    ..description = json['description'] as String
    ..whatsNew = json['whatsNew'] as String
    ..icon = json['icon'] as String
    ..builds = (json['builds'] as List)
        ?.map((e) => e == null ? null : Build.fromJson(e as Map))
        ?.toList()
    ..currentVersionName = json['currentVersionName'] as String
    ..currentVersionCode = json['currentVersionCode'] as int
    ..added = json['added'] as int
    ..lastUpdated = json['lastUpdated'] as int
    ..webSite = json['webSite'] as String
    ..translation = json['translation'] as String
    ..antiFeatures =
        (json['antiFeatures'] as List)?.map((e) => e as String)?.toList()
    ..donate = json['donate'] as String
    ..bitcoin = json['bitcoin'] as String
    ..litecoin = json['litecoin'] as String
    ..liberapay = json['liberapay'] as String
    ..openCollective = json['openCollective'] as String
    ..requirements = json['requirements'] as String
    ..metadataSrcHash = json['metadataSrcHash'] as String;
}

Map<String, dynamic> _$AppToJson(App instance) => <String, dynamic>{
      'categories': instance.categories,
      'license': instance.license,
      'authorName': instance.authorName,
      'authorEmail': instance.authorEmail,
      'sourceCode': instance.sourceCode,
      'issueTracker': instance.issueTracker,
      'changelog': instance.changelog,
      'name': instance.name,
      'packageName': instance.packageName,
      'localized': instance.localized,
      'localizedPhoneScreenshotsCache': instance.localizedPhoneScreenshotsCache,
      'summary': instance.summary,
      'description': instance.description,
      'whatsNew': instance.whatsNew,
      'icon': instance.icon,
      'builds': instance.builds,
      'currentVersionName': instance.currentVersionName,
      'currentVersionCode': instance.currentVersionCode,
      'added': instance.added,
      'lastUpdated': instance.lastUpdated,
      'webSite': instance.webSite,
      'translation': instance.translation,
      'antiFeatures': instance.antiFeatures,
      'donate': instance.donate,
      'bitcoin': instance.bitcoin,
      'litecoin': instance.litecoin,
      'liberapay': instance.liberapay,
      'openCollective': instance.openCollective,
      'requirements': instance.requirements,
      'metadataSrcHash': instance.metadataSrcHash,
    };

Build _$BuildFromJson(Map json) {
  return Build()
    ..versionName = json['versionName'] as String
    ..versionCode = json['versionCode'] as int
    ..sha256 = json['sha256'] as String
    ..apkLink = json['apkLink'] as String
    ..abis = (json['abis'] as Map)?.map(
      (k, e) => MapEntry(
          k as String, e == null ? null : ABISpecificBuild.fromJson(e as Map)),
    )
    ..size = json['size'] as int
    ..minSdkVersion = json['minSdkVersion'] as int
    ..targetSdkVersion = json['targetSdkVersion'] as int
    ..added = json['added'] as int
    ..permissions =
        (json['permissions'] as List)?.map((e) => e as String)?.toList();
}

Map<String, dynamic> _$BuildToJson(Build instance) => <String, dynamic>{
      'versionName': instance.versionName,
      'versionCode': instance.versionCode,
      'sha256': instance.sha256,
      'apkLink': instance.apkLink,
      'abis': instance.abis,
      'size': instance.size,
      'minSdkVersion': instance.minSdkVersion,
      'targetSdkVersion': instance.targetSdkVersion,
      'added': instance.added,
      'permissions': instance.permissions,
    };

ABISpecificBuild _$ABISpecificBuildFromJson(Map json) {
  return ABISpecificBuild()
    ..apkLink = json['apkLink'] as String
    ..sha256 = json['sha256'] as String;
}

Map<String, dynamic> _$ABISpecificBuildToJson(ABISpecificBuild instance) =>
    <String, dynamic>{
      'apkLink': instance.apkLink,
      'sha256': instance.sha256,
    };
