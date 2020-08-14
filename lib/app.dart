export 'package:skydroid/model/app.dart';
export 'package:skydroid/util.dart';

import 'dart:async';
import 'dart:ui';

import 'package:flutter_device_locale/flutter_device_locale.dart';
import 'package:hive/hive.dart';

Box names;
Box apps;

Box collectionNames;
Box collections;

Box localVersionCodes;

Locale locale;

List<Locale> preferredLocales;

List<String> languagePreferences;

final globalErrorStream = StreamController<Null>();
Map<String, List<String>> globalErrors = {};
