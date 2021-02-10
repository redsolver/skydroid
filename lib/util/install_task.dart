import 'dart:async';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:device_apps/device_apps.dart';
import 'package:device_info/device_info.dart';
import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:skydroid/app.dart';
import 'package:skydroid/model/app.dart';

import 'package:http/http.dart' as http;
import 'package:skydroid/util/sai_str_map.dart';

const platform = const MethodChannel('app.skydroid/native');

enum InstallState {
  none,
  downloading,
  installing,
}

class InstallTask {
  final App app;
  InstallTask(this.app);

  Application installedApplication;

  final onSetState = StreamController<Null>();
  final onError = StreamController<Function>();
  final onErrorMessage = StreamController<String>();

  String usedABI;

  int expectedVersionCode;

  String appCompatibilityError;

  bool _isDisposed = false;

  String totalFileSize;

  bool ignoreLifecycle = true;

  void dispose() {
    _isDisposed = true;
    cancelDownload();

    onSetState.close();
    onError.close();
    onErrorMessage.close();
  }

  Build currentBuild;

  void setState() {
    onSetState.add(null);
  }

  Future<void> init() async {
    currentBuild = app.builds.firstWhere(
      (element) => element.versionCode == app.currentVersionCode,
      orElse: () => null,
    );

    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;

/*     final build = app.builds.firstWhere(
      (element) => element.versionCode == app.currentVersionCode,
      orElse: () => null,
    ); */

    if (currentBuild == null) {
      appCompatibilityError = tr.errorAppInvalidCurrentBuild;

      setState();

      return;
    }

    if (androidInfo.version.sdkInt < (currentBuild.minSdkVersion ?? 0)) {
      appCompatibilityError = tr.errorAppCompatibilitySdkVersionTooLow(
        androidInfo.version.sdkInt,
        currentBuild.minSdkVersion,
      );
      setState();
      return;
    }
    if (currentBuild.abis != null) {
      for (final abi in androidInfo.supportedAbis) {
        if (currentBuild.abis.containsKey(abi)) {
          usedABI = abi;

          break;
        }
      }
    }

    if (usedABI == null) {
      if (currentBuild.apkLink == null) {
        appCompatibilityError = tr.errorAppCompatibilityNoMatchingABI(
          androidInfo.supportedAbis,
          currentBuild.abis?.keys?.toList(),
        );
        setState();
        return;
      }
    }
    //print('usedABI $usedABI');
    await _fetchInstalledApplication();

    _startLoop();
  }

  void _startLoop() async {
    while (true) {
      if (_isDisposed) break;
      _fetchInstalledApplication();
      await Future.delayed(Duration(milliseconds: 500));
    }
  }

  Future<void> _fetchInstalledApplication() async {
    final a = await DeviceApps.getApp(app.packageName);

    if (a?.versionCode != installedApplication?.versionCode) {
      //print(a);
      installedApplication = a;
      setState();
    }
    if (a == null) {
      if (localVersionCodes.containsKey(app.packageName)) {
        localVersionCodes.delete(app.packageName);
      }
    } else {
      if (localVersionCodes.get(a.packageName) != a.versionCode) {
        localVersionCodes.put(a.packageName, a.versionCode);
      }
    }
  }

  InstallState state = InstallState.none;
  double progress;

  bool _cancelDownload = false;
  StreamSubscription _downloadSub;

  void cancelDownload() {
    _cancelDownload = true;
    _downloadSub?.cancel();
    state = InstallState.none;
    setState();
  }

  Future<bool> download() async {
    String apkLink;
    String apkSha256;

    if (usedABI != null) {
      apkLink = currentBuild.abis[usedABI].apkLink;
      apkSha256 = currentBuild.abis[usedABI].sha256;
    } else {
      apkLink = currentBuild.apkLink;
      apkSha256 = currentBuild.sha256;
    }

    var appDir = await getTemporaryDirectory();
    print(appDir);

    var apk = File('${appDir.path}/apk/$apkSha256.apk');

    apkCacheTimes.put(apkSha256, DateTime.now().millisecondsSinceEpoch);

    if (apk.existsSync()) {
      downloadedApk = apk;

      return true;
    }

    state = InstallState.downloading;
    progress = null;
    setState();

    final request = http.Request(
      'GET',
      Uri.parse(
        resolveLink(
          apkLink,
        ),
      ),
    );

    _cancelDownload = false;

    print(request.url);

    final http.StreamedResponse response = await http.Client().send(request);

    state = InstallState.downloading;
    progress = 0;
    setState();

    if (_cancelDownload) return false;

    final contentLength = response.contentLength;

    totalFileSize = filesize(contentLength);
    print(contentLength);

    // List<int> bytes = [];

    final tmpApk = File('${apk.path}.downloading');

    tmpApk.createSync(recursive: true);

    final fileStream = tmpApk.openWrite();

    int downloadedLength = 0;

    var output = new AccumulatorSink<Digest>();
    var input = sha256.startChunkedConversion(output);

    final completer = Completer<bool>();

    _downloadSub = response.stream.listen(
      (List<int> newBytes) {
        downloadedLength += newBytes.length;
        fileStream.add(newBytes);
        input.add(newBytes);

        progress = downloadedLength / contentLength;
        setState();

        //   notifyListeners();
      },
      onDone: () async {
        input.close();
        final hash = output.events.single;
        await fileStream.close();

        if (hash.toString() != apkSha256) {
          onErrorMessage.add(tr.downloadHashMismatchErrorDialogTitle);
          onError.add(
            (context) => AlertDialog(
              title: Text(tr.downloadHashMismatchErrorDialogTitle),
              content: Text(
                  tr.downloadHashMismatchErrorDialogContent(apkSha256, hash)),
              actions: [
                FlatButton(
                  onPressed: Navigator.of(context).pop,
                  child: Text(
                    tr.errorDialogCloseButton,
                    style: dialogActionTextStyle(context),
                  ),
                ),
              ],
            ),
          );
          completer.complete(false);
          return;
        }
        print(hash.toString()); // Check!
        // notifyListeners();

        await tmpApk.rename(apk.path);

        print('done');

        downloadedApk = apk;

        completer.complete(true);
      },
      onError: (e) {
        // TODO Show print(e);
        completer.complete(false);
      },
      cancelOnError: true,
    );
    return completer.future;
  }

  File downloadedApk;

  Future<void> install(/* File apk, int versionCode */) async {
    if (downloadedApk == null) throw 'APK not downloaded';

    final versionCode = currentBuild.versionCode;

    if (isShizukuEnabled) {
      void showShizukuErrorDialog(Widget content, String text) {
        final customErrorMessageTranslation =
            saiStrMap['saiStr_' + text.trim().split('\n').last];

        final errorMessage = customErrorMessageTranslation == null
            ? text
            : customErrorMessageTranslation();

        onErrorMessage.add(errorMessage);
        onError.add(
          (context) => AlertDialog(
            title: Text(
              tr.errorAppInstallationShizuku,
            ),
            content: Text(errorMessage),
            actions: [
              FlatButton(
                onPressed: Navigator.of(context).pop,
                child: Text(
                  tr.errorDialogCloseButton,
                  style: dialogActionTextStyle(context),
                ),
              ),
            ],
          ),
        );
      }

      final bool permissionGranted =
          await platform.invokeMethod('checkShizukuPermission');
      if (!permissionGranted) {
        platform.invokeMethod('requestShizukuPermission');

        showShizukuErrorDialog(
          Text(tr.appPageInstallingShizukuErrorPermissionNotGranted),
          tr.appPageInstallingShizukuErrorPermissionNotGranted,
        );

        return;
      }

/*       await platform.invokeMethod(
        'launch',
        {
          'packageName': '${app.packageName}',
        },
      ); */

/*       setState(() {
        progress = 1;
        state = InstallState.none;
        expectedVersionCode = versionCode;
      }); */

      final result = await platform.invokeMethod(
        'installWithShizuku',
        {
          'path': '${downloadedApk.path}',
        },
      );

      print('INSTALLATION ID $result');

      progress = null;
      state = InstallState.installing;
      expectedVersionCode = versionCode;
      setState();

      while (true) {
        final shizukuInstallationStatus =
            await platform.invokeMethod('fetchShizukuInstallationStatus');

        // print(shizukuInstallationStatus);

        final status = shizukuInstallationStatus[0];

        if (status == 'installer_state_installed') {
          if (!_isDisposed) {
            progress = 1;
            state = InstallState.none;
            expectedVersionCode = versionCode;

            setState();
          }
          break;
        } else if (status == 'installer_state_failed') {
          final shortForm =
              (shizukuInstallationStatus[1] ?? '').split('|||').first;

          final parts = shortForm.split('|');

          final error = parts.last;

          if (error == 'installer_error_shizuku_unavailable') {
            showShizukuErrorDialog(
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tr.appPageInstallingShizukuErrorNotRunning),
                  SizedBox(
                    height: 8,
                  ),
                  RaisedButton(
                    onPressed: () {
                      platform.invokeMethod(
                        'launch',
                        {
                          'packageName': shizukuPackageName,
                        },
                      );
                    },
                    child:
                        Text(tr.appPageInstallingShizukuErrorNotRunningButton),
                  ),
                ],
              ),
              tr.appPageInstallingShizukuErrorNotRunning,
            );
          } else {
            showShizukuErrorDialog(
              Text(parts.join('\n')),
              parts.last,
            );
          }

          if (!_isDisposed) {
            progress = 1;
            state = InstallState.none;
            expectedVersionCode = versionCode;
            setState();
          }

          break;
        } else if (status == 'installer_state_installing') {}

        // installer_state_installing, installer_state_installed, installer_state_failed

        await Future.delayed(Duration(milliseconds: 50));
      }
    } else {
      progress = 1;
      state = InstallState.none;
      expectedVersionCode = versionCode;
      setState();
      final result = await platform.invokeMethod(
        'install',
        {
          'path': '${downloadedApk.path}',
        },
      );

      if (result == 'show') {
        ignoreLifecycle = false;
      }
    }
  }
}
