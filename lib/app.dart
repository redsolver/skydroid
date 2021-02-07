export 'package:skydroid/model/app.dart';
export 'package:skydroid/util.dart';

import 'dart:async';
import 'dart:ui';

import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'package:flutter_gen/gen_l10n/translations.dart';

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

Translations tr;
AndroidDeviceInfo androidInfo;

final categoryKeys = {
  'Connectivity': () => tr.categoryConnectivity,
  'Development': () => tr.categoryDevelopment,
  'Games': () => tr.categoryGames,
  'Graphics': () => tr.categoryGraphics,
  'Internet': () => tr.categoryInternet,
  'Money': () => tr.categoryMoney,
  'Multimedia': () => tr.categoryMultimedia,
  'Navigation': () => tr.categoryNavigation,
  'Phone & SMS': () => tr.categoryPhoneAndSMS,
  'Reading': () => tr.categoryReading,
  'Science & Education': () => tr.categoryScienceAndEducation,
  'Security': () => tr.categorySecurity,
  'Sports & Health': () => tr.categorySportsAndHealth,
  'System': () => tr.categorySystem,
  'Theming': () => tr.categoryTheming,
  'Time': () => tr.categoryTime,
  'Writing': () => tr.categoryWriting,
};

String translateCategoryName(String category) {
  if (categoryKeys.containsKey(category)) {
    return categoryKeys[category]();
  }
  return category;
}
