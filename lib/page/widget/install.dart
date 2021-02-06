import 'dart:async';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:device_apps/device_apps.dart';
import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animation_progress_bar/flutter_animation_progress_bar.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:skydroid/app.dart';

class InstallWidget extends StatefulWidget {
  final App app;
  InstallWidget(this.app);

  @override
  _InstallWidgetState createState() => _InstallWidgetState();
}

enum InstallState {
  none,
  downloading,
  // installing,
}

class _InstallWidgetState extends State<InstallWidget>
    with WidgetsBindingObserver {
  App get app => widget.app;

  InstallState state = InstallState.none;
  StreamSubscription sub;
  bool cancelDownload = false;

  double progress;

  String totalFileSize;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _getStatus();
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cancelDownload = true;
    sub?.cancel();
    super.dispose();
  }

  int expectedVersionCode;

  Application application;

  _getStatus() async {
    while (true) {
      final a = await DeviceApps.getApp(app.packageName);
      if (!mounted) break;
      if (a?.versionCode != application?.versionCode) {
        //print(a);
        if (mounted)
          setState(() {
            application = a;
          });
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
      await Future.delayed(Duration(seconds: 1));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // print('state == $state');
    if (state == AppLifecycleState.resumed && !ignoreLifecycle) {
      ignoreLifecycle = true;
      platform.invokeMethod(
        'install',
        {
          'path': '${lastApk.path}',
        },
      );
    }
  }

  File lastApk;

  bool ignoreLifecycle = true;

  _install(File apk, int versionCode) async {
    setState(() {
      progress = 1;
      state = InstallState.none;
      expectedVersionCode = versionCode;
    });
    lastApk = apk;
    final result = await platform.invokeMethod(
      'install',
      {
        'path': '${apk.path}',
      },
    );

    if (result == 'show') {
      ignoreLifecycle = false;
    }
  }

  _downloadAndStartInstall() async {
    final build = app.builds
        .firstWhere((element) => element.versionCode == app.currentVersionCode);

    var appDir = await getTemporaryDirectory();
    print(appDir);

    var apk = File('${appDir.path}/apk/${build.sha256}.apk');

    if (apk.existsSync()) {
      _install(apk, build.versionCode);
      return;
    }

    setState(() {
      state = InstallState.downloading;
      progress = null;
    });

    final request = http.Request(
      'GET',
      Uri.parse(
        resolveLink(
          build.apkLink,
        ),
      ),
    );
    setState(() {
      state = InstallState.downloading;
      progress = 0;
    });
    cancelDownload = false;

    print(request.url);

    final http.StreamedResponse response = await http.Client().send(request);

    if (cancelDownload) return;

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

    sub = response.stream.listen(
      (List<int> newBytes) {
        downloadedLength += newBytes.length;
        fileStream.add(newBytes);
        input.add(newBytes);

        setState(() {
          progress = downloadedLength / contentLength;
        });

        //   notifyListeners();
      },
      onDone: () async {
        /*  setState(() {
                              checkingIntegrity = true;
                            }); */

        input.close();
        final hash = output.events.single;
        await fileStream.close();
        /*    setState(() {
                              checkingIntegrity = false;
                            }); */

        if (hash.toString() != build.sha256) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(tr.downloadHashMismatchErrorDialogTitle),
              content: Text(tr.downloadHashMismatchErrorDialogContent(
                  build.sha256, hash)),
              actions: [
                FlatButton(
                  onPressed: Navigator.of(context).pop,
                  child: Text(tr.errorDialogCloseButton),
                ),
              ],
            ),
          );
          return;
        }
        print(hash.toString()); // Check!
        // notifyListeners();

        await tmpApk.rename(apk.path);

        print('done');
        _install(apk, build.versionCode);
      },
      onError: (e) {
        print(e);
      },
      cancelOnError: true,
    );

    /*  */
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      /*  color: Theme.of(context).primaryColor,
      elevation: 4, */
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000),
            spreadRadius: 0,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      /* 
      width: double.infinity, */
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(
                left: 8.0,
                right: 8.0,
                top: 8.0,
                bottom: state == InstallState.downloading ? 0 : 8),
            child: Row(
              children: <Widget>[
                if (state == InstallState.none) ...[
                  if (application == null && expectedVersionCode == null)
                    Expanded(
                      child: RaisedButton(
                        color: Theme.of(context).accentColor,
                        onPressed: () async {
                          _downloadAndStartInstall();
                        },
                        child: Text(
                          tr.appPageInstallButton(
                            app.currentVersionName,
                          ),
                        ),
                      ),
                    ),
                  if (expectedVersionCode != application?.versionCode &&
                      expectedVersionCode != null) ...[
                    Expanded(
                      child: RaisedButton(
                        color: Theme.of(context).accentColor,
                        onPressed: () async {
                          _downloadAndStartInstall();
                        },
                        child: Text(tr.appPageRetryInstallButton),
                      ),
                    ),
                    Expanded(
                        child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        tr.appPageInstallingApkProcess,
                      ),
                    ))
                  ],
                  if ((expectedVersionCode == null ||
                          expectedVersionCode == application?.versionCode) &&
                      application != null) ...[
                    Expanded(
                      child: RaisedButton(
                        color: Theme.of(context).errorColor,
                        onPressed: () async {
                          expectedVersionCode = null;
                          await platform.invokeMethod(
                            'uninstall',
                            {
                              'packageName': '${app.packageName}',
                            },
                          );
                        },
                        child: Text(
                            tr.appPageUninstallButton(application.versionName)),
                      ),
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    application.versionCode >= app.currentVersionCode
                        ? Expanded(
                            child: RaisedButton(
                              color: Theme.of(context).accentColor,
                              onPressed: () async {
                                await platform.invokeMethod(
                                  'launch',
                                  {
                                    'packageName': '${app.packageName}',
                                  },
                                );
                              },
                              child: Text(tr.appPageLaunchAppButton),
                            ),
                          )
                        : Expanded(
                            child: RaisedButton(
                              color: Theme.of(context).accentColor,
                              onPressed: () async {
                                _downloadAndStartInstall();
                              },
                              child: Text(tr
                                  .appPageUpdateButton(app.currentVersionName)),
                            ),
                          ),
                  ],
                ],
                if (state == InstallState.downloading) ...[
                  Expanded(
                    child: RaisedButton(
                      color: Theme.of(context).errorColor,
                      onPressed: () async {
                        cancelDownload = true;
                        await sub?.cancel();
                        setState(() {
                          state = InstallState.none;
                        });
                      },
                      child: Text(tr.dialogCancel),
                    ),
                  ),
                  Expanded(
                      child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      totalFileSize == null
                          ? tr.appPageInstallationDownloadStarting
                          : tr.appPageInstallationProgress(
                              (progress * 100).round(), totalFileSize),
                      textAlign: TextAlign.center,
                    ),
                  ))
                ]
              ],
            ),
          ),
          if (state == InstallState.downloading)
            SizedBox(
              height: 8,
              child: LinearProgressIndicator(
                backgroundColor: Theme.of(context).dividerColor,
                value: progress,
              ),
            ),
        ],
      ),
    );
  }
}

const platform = const MethodChannel('app.skydroid/native');
