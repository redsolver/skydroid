// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collection.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CollectionAdapter extends TypeAdapter<Collection> {
  @override
  final int typeId = 4;

  @override
  Collection read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Collection()
      ..title = fields[1] as String
      ..description = fields[2] as String
      ..icon = fields[3] as String
      ..apps = (fields[4] as List)?.cast<AppReference>()
      ..srcHash = fields[250] as String;
  }

  @override
  void write(BinaryWriter writer, Collection obj) {
    writer
      ..writeByte(5)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.icon)
      ..writeByte(4)
      ..write(obj.apps)
      ..writeByte(250)
      ..write(obj.srcHash);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AppReferenceAdapter extends TypeAdapter<AppReference> {
  @override
  final int typeId = 5;

  @override
  AppReference read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppReference()
      ..name = fields[1] as String
      ..verifiedMetadataHashes = (fields[2] as List)?.cast<String>();
  }

  @override
  void write(BinaryWriter writer, AppReference obj) {
    writer
      ..writeByte(2)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.verifiedMetadataHashes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppReferenceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Collection _$CollectionFromJson(Map json) {
  return Collection()
    ..title = json['title'] as String
    ..description = json['description'] as String
    ..icon = json['icon'] as String
    ..apps = (json['apps'] as List)
        ?.map((e) => e == null ? null : AppReference.fromJson(e as Map))
        ?.toList()
    ..srcHash = json['srcHash'] as String;
}

Map<String, dynamic> _$CollectionToJson(Collection instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'icon': instance.icon,
      'apps': instance.apps,
      'srcHash': instance.srcHash,
    };

AppReference _$AppReferenceFromJson(Map json) {
  return AppReference()
    ..name = json['name'] as String
    ..verifiedMetadataHashes = (json['verifiedMetadataHashes'] as List)
        ?.map((e) => e as String)
        ?.toList();
}

Map<String, dynamic> _$AppReferenceToJson(AppReference instance) =>
    <String, dynamic>{
      'name': instance.name,
      'verifiedMetadataHashes': instance.verifiedMetadataHashes,
    };
