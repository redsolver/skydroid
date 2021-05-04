import 'dart:io';

import 'package:flutter/material.dart';
import 'package:skydroid/app.dart';
import 'package:skydroid/util/install_task.dart';

class InstallWidget extends StatefulWidget {
  final App app;
  InstallWidget(this.app);

  @override
  _InstallWidgetState createState() => _InstallWidgetState();
}

class _InstallWidgetState extends State<InstallWidget>
    with WidgetsBindingObserver {
  App get app => widget.app;

  InstallTask task;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    task = InstallTask(widget.app);

    task.onSetState.stream.listen((event) {
      if (mounted) setState(() {});
    });
    task.onError.stream.listen((builder) {
      showDialog(
        context: context,
        builder: builder,
      );
    });

    task.init();

    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    task.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !task.ignoreLifecycle) {
      task.ignoreLifecycle = true;
      platform.invokeMethod(
        'install',
        {
          'path': '${task.downloadedApk.path}',
        },
      );
    }
  }

  void _downloadAndStartInstall() async {
    await task.download();
    await task.install();
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
                bottom: task.state == InstallState.downloading ? 0 : 8),
            child: task.appCompatibilityError != null
                ? Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.appCompatibilityError,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: <Widget>[
                      if (task.state == InstallState.installing) ...[
                        Expanded(
                            child: Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              tr.appPageInstallingShizukuProcess,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ))
                      ],
                      if (task.state == InstallState.none) ...[
                        if (task.installedApplication == null &&
                            task.expectedVersionCode == null)
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
                        if (task.expectedVersionCode !=
                                task.installedApplication?.versionCode &&
                            task.expectedVersionCode != null) ...[
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
                        if ((task.expectedVersionCode == null ||
                                task.expectedVersionCode ==
                                    task.installedApplication?.versionCode) &&
                            task.installedApplication != null) ...[
                          Expanded(
                            child: RaisedButton(
                              color: Theme.of(context).errorColor,
                              onPressed: () async {
                                task.expectedVersionCode = null;
                                await platform.invokeMethod(
                                  'uninstall',
                                  {
                                    'packageName': '${app.packageName}',
                                  },
                                );
                              },
                              child: Text(tr.appPageUninstallButton(
                                  task.installedApplication.versionName)),
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          task.installedApplication.versionCode >=
                                  app.currentVersionCodeForDeviceArchitecture
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
                                    child: Text(tr.appPageUpdateButton(
                                        app.currentVersionName)),
                                  ),
                                ),
                        ],
                      ],
                      if (task.state == InstallState.downloading) ...[
                        Expanded(
                          child: RaisedButton(
                            color: Theme.of(context).errorColor,
                            onPressed: () async {
                              task.cancelDownload();
                            },
                            child: Text(tr.dialogCancel),
                          ),
                        ),
                        Expanded(
                            child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            task.totalFileSize == null
                                ? tr.appPageInstallationDownloadStarting
                                : tr.appPageInstallationProgress(
                                    ((task.progress ?? 0) * 100).round(),
                                    task.totalFileSize),
                            textAlign: TextAlign.center,
                          ),
                        ))
                      ]
                    ],
                  ),
          ),
          if (task.state == InstallState.downloading ||
              task.state == InstallState.installing)
            SizedBox(
              height: 8,
              child: LinearProgressIndicator(
                backgroundColor: Theme.of(context).dividerColor,
                value: task.progress,
              ),
            ),
        ],
      ),
    );
  }
}
