import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'collection.g.dart';

@HiveType(typeId: 4)
@JsonSerializable(anyMap: true)
class Collection {
  @HiveField(1)
  String title;
  @HiveField(2)
  String description;
  @HiveField(3)
  String icon;

  @HiveField(4)
  List<AppReference> apps;

  @HiveField(250)
  String srcHash;

  Collection();

  factory Collection.fromJson(Map<dynamic, dynamic> json) =>
      _$CollectionFromJson(json);

  Map<String, dynamic> toJson() => _$CollectionToJson(this);
}

@HiveType(typeId: 5)
@JsonSerializable(anyMap: true)
class AppReference {
  @HiveField(1)
  String name;
  @HiveField(2)
  List<String> verifiedMetadataHashes;

  AppReference();

  factory AppReference.fromJson(Map<dynamic, dynamic> json) =>
      _$AppReferenceFromJson(json);

  Map<String, dynamic> toJson() => _$AppReferenceToJson(this);
}
