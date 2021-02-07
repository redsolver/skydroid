import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:crypto/crypto.dart';
import 'package:device_apps/device_apps.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_device_locale/flutter_device_locale.dart';

import 'package:http/http.dart' as http;
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pool/pool.dart';
import 'package:preferences/preferences.dart';
import 'package:skydroid/app.dart';
import 'package:skydroid/data/categories.dart';
import 'package:skydroid/model/collection.dart';
import 'package:skydroid/page/app.dart';
import 'package:skydroid/page/collections.dart';
import 'package:skydroid/page/settings.dart';
import 'package:skydroid/theme.dart';
import 'package:uni_links/uni_links.dart';
import 'package:yaml/yaml.dart';

import 'package:flutter_gen/gen_l10n/translations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PrefService.init();
  PrefService.setDefaultValues({
    'theme': 'light',
    'dnsUrl': 'https://dns.skydroid.app', // ! Must support Multi-DoH
    'skynetPortal': 'https://siasky.net',
  });

  locale = await DeviceLocale.getCurrentLocale();
  preferredLocales = await DeviceLocale.getPreferredLocales();

  languagePreferences = [
    locale.toLanguageTag(),
    locale.languageCode,
    for (var l in preferredLocales) ...[
      l.toLanguageTag(),
      l.languageCode,
    ],
  ]; // 1,34 MB pro 255 Apps

  print('Language preferences: $languagePreferences');

  await Hive.initFlutter();
  Hive.registerAdapter(AppAdapter());
  Hive.registerAdapter(BuildAdapter());
  Hive.registerAdapter(CollectionAdapter());
  Hive.registerAdapter(AppReferenceAdapter());
  Hive.registerAdapter(ABISpecificBuildAdapter());

  names = await Hive.openBox('names'); // name -> {name ...}

  if (names.isEmpty) {
    names.put('skydroid.app', {
      'name': 'skydroid.app',
    });
  }
  apps = await Hive.openBox('apps');
  localVersionCodes = await Hive.openBox('localVersionCodes');

  collectionNames = await Hive.openBox('collectionNames');
  collections = await Hive.openBox('collections');

  workTroughReqs();
  final deviceInfo = DeviceInfoPlugin();

  deviceInfo.androidInfo.then((value) => androidInfo = value);

  runApp(
    MyApp(),
  );
}

final httpClient = http.Client();

class MyApp extends StatelessWidget {
  ThemeData _buildThemeData(String theme) {
    var _accentColor = Color(0xff1ed660); //Color(0xff57b560);

    var brightness =
        ['light', 'sepia'].contains(theme) ? Brightness.light : Brightness.dark;

    var themeData = ThemeData(
        brightness: brightness,
        primaryColor:
            brightness == Brightness.dark ? Colors.grey[850] : Colors.grey[50],
        accentColor: _accentColor,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        toggleableActiveColor: _accentColor,
        highlightColor: _accentColor,
        buttonColor: _accentColor,
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: _accentColor,
        ),
        buttonTheme: ButtonThemeData(
          textTheme: ButtonTextTheme.primary,
          buttonColor: _accentColor,
        ),
        textTheme: TextTheme(
          button: TextStyle(color: _accentColor),
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusColor: _accentColor,
          fillColor: _accentColor,
        ));

    if (theme == 'sepia') {
      Color backgroundColor = Color(0xffF7ECD5);
      themeData = themeData.copyWith(
        primaryColor: backgroundColor,
        backgroundColor: backgroundColor,
        scaffoldBackgroundColor: backgroundColor,
        dialogBackgroundColor: backgroundColor,
        canvasColor: backgroundColor,
      );
    } else if (theme == 'black') {
      Color backgroundColor = Colors.black;
      themeData = themeData.copyWith(
        primaryColor: backgroundColor,
        backgroundColor: backgroundColor,
        scaffoldBackgroundColor: backgroundColor,
        dialogBackgroundColor: backgroundColor,
        canvasColor: backgroundColor,
      );
    }

    return themeData;
  }

  @override
  Widget build(BuildContext context) {
    //final str = PrefService.getString('theme');

    return AppTheme(
      data: (theme) => _buildThemeData(theme),
      themedWidgetBuilder: (context, theme) {
        return MaterialApp(
          title: 'SkyDroid',
          theme: theme,
          home: MyHomePage(),
          debugShowCheckedModeBanner: false,
          localizationsDelegates: Translations.localizationsDelegates,
          supportedLocales: Translations.supportedLocales,
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

Map<String, StreamController<bool>> metadataStreams = {};

Stream<bool> getStream(String name) {
  metadataStreams.putIfAbsent(name, () => StreamController.broadcast());
  return metadataStreams[name].stream;
}

addToStream(String name) {
  metadataStreams.putIfAbsent(name, () => StreamController.broadcast());
  metadataStreams[name].add(true);
}

Map<String, int> loadingState = {};

class _MyHomePageState extends State<MyHomePage> {
  int currentPage = 0;

  StreamSubscription _sub;

  processLink(String link) async {
    final name =
        link.split('/').reversed.firstWhere((element) => element.isNotEmpty);

    if (!names.containsKey(name)) {
      await addName(name);
    }

    final App app = apps.get(name);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AppPage(
          name,
          app,
        ),
      ),
    );
    addToStream(name);
    setState(() {});
  }

  Future<Null> initUniLinks() async {
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      String initialLink = await getInitialLink();

      if (initialLink != null) processLink(initialLink);

      // Parse the link and warn the user, if it is not correct,
      // but keep in mind it could be `null`.

      // Attach a listener to the stream
      _sub = getLinksStream().listen((String link) {
        // Parse the link and warn the user, if it is not correct
        processLink(link);
      }, onError: (err) {
        // Handle exception by warning the user their action did not succeed
      });
    } on PlatformException {
      // Handle exception by warning the user their action did not succeed
      // return?
    }
  }

  @override
  void initState() {
    initUniLinks();

    updateAllCollections();

    updateAllNames();
    super.initState();
  }

  @override
  void dispose() {
    globalErrorStream.close();
    _sub.cancel();
    super.dispose();
  }

  bool _loading = true;

  Future updateAllCollections() async {
    print('updateAllCollections');

    List<Future> collectionFutures = [];
    List<Future> futures = [];

    for (var name in collectionNames.values) {
      collectionFutures.add(() async {
        try {
          final n = name['name'];
          //print('Update $n');

          var res = await checkName(n, type: 'collection');

          //print(res);

          final Collection collection = collections.get(name['name']);

          if (res['hash'] != collection?.srcHash) {
            //print('New collection Hash!!!');
            collectionNames.put(n, res);
            await updateMetadata(res, 'collection');
            final Collection collection = collections.get(name['name']);

            List<Future> localFutures = [];

            for (var app in collection.apps) {
              if (!names.containsKey(app.name)) {
                names.put(app.name, {
                  'name': app.name,
                });

                localFutures.add(updateName(app.name));
              }
            }

            if (localFutures.isNotEmpty) {
              if (mounted) setState(() {});
              futures.addAll(localFutures);
            }
          }
        } catch (e, st) {
          addError(e, 'collection:${name['name']}');
        }
      }());
    }

    //print('Awaiting collectionFutures $collectionFutures');

    await Future.wait(collectionFutures);

    //print('Awaiting futures $futures');

    await Future.wait(futures);
    if (mounted) setState(() {});
  }

  Future updateAllNames() async {
    print('updateAllNames');
    List<Future> futures = [];
    names.values.forEach((name) async {
      futures.add(updateName(name['name']));
    });
    await Future.wait(futures);

    _loading = false;
    if (mounted) setState(() {});
  }

  Future updateName(String name) async {
    // print('update name $name');
    try {
      loadingState[name] = 1;
      addToStream(name);
      var res = await checkName(name, type: 'app');
      final App app = apps.get(name);
      if (res['hash'] != app?.metadataSrcHash) {
        //print('New Hash!!!');
        names.put(name, res);
        await updateMetadata(res, 'app');
      }
      loadingState[name] = 0;
      addToStream(name);
    } catch (e, st) {
      //print('');
      addError(e, 'app:$name');

      if (kDebugMode) {
        print('app:$name');
        print(e);
        print(st);
      }
      //print('');
      loadingState[name] = 3;
      addToStream(name);
      /*  print(e);
      print(st); */
    }
  }

  addError(
    dynamic exception,
    dynamic ctx,
  ) {
    final e = exception.toString();

    if (!globalErrors.containsKey(e)) {
      globalErrors[e] = [];
    }
    globalErrors[e].add(ctx.toString());

    globalErrorStream.add(null);
  }

  removeName(String name) async {
    var res = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(Translations.of(context).removeNameDialogTitle),
              content:
                  Text(Translations.of(context).removeNameDialogContent(name)),
              actions: <Widget>[
                FlatButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(Translations.of(context).dialogCancel),
                ),
                FlatButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: Text(Translations.of(context).removeNameDialogConfirm),
                ),
              ],
            ));

    if (res == true) {
      if (apps.containsKey(name)) await apps.delete(name);
      await names.delete(name);
      setState(() {});
    }
  }

  int hiddenCount = 0;

  String searchTerm;
  String categoryFilter;

  List<String> namesOrder;
  List<String> updateNamesOrder() {
    List<String> preparedKeys = apps.keys.toList().cast<String>();

    preparedKeys.sort(
        (a, b) => -apps.get(a).lastUpdated.compareTo(apps.get(b).lastUpdated));

    List<String> updateKeys = [];
    //List<String> installedKeys = [];
    List<String> keys = [];

    int hiddenCounter = 0;
    List<String> searchTerms;

    if (searchTerm != null) {
      searchTerms = searchTerm.trim().toLowerCase().split(' ');
    }

    for (var key in preparedKeys) {
      final App a = apps.get(key);

      if (categoryFilter != null) {
        if (!(a.categories ?? []).contains(categoryFilter)) {
          continue;
        }
      }

      if (searchTerms != null) {
        String searchStr =
            '${a.localizedName} ${a.localizedSummary}'.toLowerCase();
        bool contains = true;

        for (var term in searchTerms) {
          if (!searchStr.contains(term)) {
            contains = false;
            break;
          }
        }
        if (!contains) {
          continue;
        }
      }

      if (localVersionCodes.containsKey(a.packageName)) {
        if (a.currentVersionCode > localVersionCodes.get(a.packageName)) {
          updateKeys.add(key);
          continue;
        } else {
          keys.add(key);
          continue;
        }
      }
      keys.add(key);
    }

    for (var key in names.keys) {
      if (!preparedKeys.contains(key)) keys.add(key);
    }

    if (hiddenCounter != hiddenCount) {
      hiddenCount = hiddenCounter;
    }
    return [...updateKeys, ...keys];
/*     setState(() {
    }); */
  }

  final textCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    tr = Translations.of(context);

    if (currentPage == 0) {
      print('|||| setState');
      namesOrder = updateNamesOrder();
    }
    return Scaffold(
      appBar: AppBar(
        title: (searchTerm == null || currentPage != 0)
            ? Text(
                'SkyDroid' +
                    (currentPage == 0
                        ? (categoryFilter == null
                            ? ''
                            : ' • ${translateCategoryName(categoryFilter)}')
                        : currentPage == 1
                            ? ' • ${Translations.of(context).navigationCollectionsPageTitle}'
                            : ' • ${Translations.of(context).navigationSettingsPageTitle}'),
              )
            : TextField(
                autofocus: true,
                controller: textCtrl,
                onChanged: (value) {
                  setState(() {
                    searchTerm = value.toLowerCase();
                  });
                },
              ),
        actions: currentPage == 0
            ? <Widget>[
                if (searchTerm != null)
                  IconButton(
                    icon: Icon(
                      MdiIcons.close,
                    ),
                    onPressed: () {
                      textCtrl.text = '';
                      setState(() {
                        searchTerm = null;
                      });
                    }, // TODO Full-text search
                  ),
                if (searchTerm == null)
                  IconButton(
                    icon: Icon(
                      MdiIcons.magnify,
                    ),
                    onPressed: () {
                      setState(() {
                        searchTerm = '';
                      });
                    },
                  ),
                categoryFilter == null
                    ? IconButton(
                        icon: Icon(
                          MdiIcons.filter,
                        ),
                        onPressed: () async {
                          var res = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                    title: Text(
                                      Translations.of(context)
                                          .filterDialogTitle,
                                    ),
                                    content: SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height -
                                              400,
                                      width: 200,
                                      child: Scrollbar(
                                        child: ListView(
                                          children: [
                                            for (var cat in existingCategories)
                                              InkWell(
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                      12.0),
                                                  child: Text(
                                                      translateCategoryName(
                                                          cat)),
                                                ),
                                                onTap: () {
                                                  Navigator.of(context)
                                                      .pop(cat);
                                                },
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    actions: [
                                      FlatButton(
                                        onPressed: Navigator.of(context).pop,
                                        child: Text(
                                          Translations.of(context).dialogCancel,
                                        ),
                                      ),
                                    ],
                                  ));

                          if (res != null) {
                            setState(() {
                              categoryFilter = res;
                            });
                          }
                        },
                      )
                    : IconButton(
                        color: Theme.of(context).accentColor,
                        icon: Icon(
                          MdiIcons.filterRemove,
                        ),
                        onPressed: () {
                          setState(() {
                            categoryFilter = null;
                          });
                        },
                      ),
              ]
            : [],
      ),
      body: Stack(
        children: [
          currentPage != 0
              ? (currentPage == 1
                  ? CollectionsPage(
                      refreshCallback: updateAllCollections,
                    )
                  : SettingsPage())
              : Column(
                  children: [
                    if (_loading)
                      SizedBox(
                        height: 4,
                        child: LinearProgressIndicator(),
                      ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          globalErrors = {};
                          globalErrorStream.add(null);
                          await Future.wait(
                              [updateAllCollections(), updateAllNames()]);
                        },
                        child: namesOrder.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    tr.appListPageEmptyWarning,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : Scrollbar(
                                child: ListView.builder(
                                  itemCount: namesOrder.length,
                                  padding: EdgeInsets.only(
                                    top: _loading ? 4 : 8,
                                    bottom: 80,
                                  ),
                                  itemBuilder: (context, index) {
                                    final name = names.get(namesOrder[index]);

                                    return ConstrainedBox(
                                      constraints:
                                          BoxConstraints(maxHeight: 200),
                                      child: StreamBuilder<bool>(
                                          stream: getStream(name['name']),
                                          initialData: false,
                                          builder: (context, snap) {
                                            final App app =
                                                apps.get(name['name']);

                                            String state;

                                            bool loading;

                                            bool error = false;
                                            if (app == null) {
                                              state = tr.appListLoadingMetadata;
                                              loading = true;
                                            } else {
                                              final lSt =
                                                  loadingState[name['name']];
                                              state = app.localizedSummary;
                                              if (lSt == 0) {
                                                loading = false;
                                              } else if (lSt == 1) {
                                                //   state = 'Checking name...';
                                                loading = true;
                                              } else if (lSt == 3) {
                                                //   state = 'Checking name...';
                                                loading = false;
                                                error = true;
                                              } else {
                                                //state = 'Updating metadata...';
                                                loading = true;
                                              }
                                            }
                                            //print('b');

                                            if (app != null) {
                                              return ListTile(
                                                  onLongPress: () {
                                                    removeName(name['name']);
                                                  },
                                                  onTap: () async {
                                                    await Navigator.of(context)
                                                        .push(
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            AppPage(
                                                          name['name'],
                                                          app,
                                                        ),
                                                      ),
                                                    );
                                                    addToStream(name['name']);
                                                    setState(() {});
                                                  },
                                                  leading: Hero(
                                                    tag:
                                                        'app-icon-${name['name']}',
                                                    child: (app.icon == null ||
                                                            app.icon.endsWith(
                                                                '.xml'))
                                                        ? Image.asset(
                                                            'assets/icon/fallback.png',
                                                            width: 64,
                                                            height: 64,
                                                          )
                                                        : CachedNetworkImage(
                                                            imageUrl:
                                                                resolveLink(
                                                                    app.icon),
                                                            width: 64,
                                                            height: 64,
                                                          ),
                                                  ),
                                                  title: Text(
                                                      '${app.localizedName}'), // optional (${name['name']})
                                                  subtitle: state == null
                                                      ? null
                                                      : Text(
                                                          state,
                                                          maxLines: 3,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                  trailing: SizedBox(
                                                    width: 4,
                                                    height: 42,
                                                    child: loading
                                                        ? LinearProgressIndicator(
                                                            valueColor:
                                                                AlwaysStoppedAnimation(
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .onSurface,
                                                            ),
                                                            backgroundColor:
                                                                Theme.of(
                                                                        context)
                                                                    .dividerColor,
                                                          )
                                                        : FutureBuilder<
                                                                Application>(
                                                            future: DeviceApps
                                                                .getApp(app
                                                                    .packageName),
                                                            builder: (context,
                                                                snap) {
                                                              /*  try { */
                                                              if (error) {
                                                                return Container(
                                                                  color: Colors
                                                                      .red,
                                                                );
                                                              }
                                                              if (snap
                                                                  .hasData) {
                                                                final a =
                                                                    snap.data;
                                                                if (a == null) {
                                                                  if (localVersionCodes
                                                                      .containsKey(
                                                                          a.packageName)) {
                                                                    localVersionCodes
                                                                        .delete(
                                                                            a.packageName);
                                                                  }
                                                                } else {
                                                                  if (localVersionCodes
                                                                          .get(a
                                                                              .packageName) !=
                                                                      a.versionCode) {
                                                                    localVersionCodes.put(
                                                                        a.packageName,
                                                                        a.versionCode);
                                                                  }
                                                                }
                                                              }
                                                              if (!snap
                                                                      .hasData ||
                                                                  snap.data ==
                                                                      null)
                                                                return SizedBox();

                                                              if (snap.data
                                                                      .versionCode <
                                                                  app.currentVersionCode) {
                                                                return Container(
                                                                  color: Colors
                                                                      .orange,
                                                                );
                                                              } else {
                                                                return Container(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .accentColor,
                                                                );
                                                              }
                                                              /*  } catch (e, st) {
                                                                print(e);
                                                                print(st);
                                                              } */
                                                            }),
                                                  ));
                                            } else {
                                              return ListTile(
                                                onLongPress: () {
                                                  removeName(name['name']);
                                                },
                                                title: Text(name['name']),
                                                subtitle: Text(state),
                                                trailing:
                                                    CircularProgressIndicator(
                                                  backgroundColor:
                                                      Theme.of(context)
                                                          .dividerColor,
                                                ),
                                              );
                                            }
                                          }),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
          StreamBuilder(
              stream: globalErrorStream.stream,
              builder: (context, snapshot) {
                if (globalErrors.isEmpty) {
                  return SizedBox();
                }

                return Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: double.infinity,
                    child: Container(
                      color: Colors.yellow,
                      padding: const EdgeInsets.only(
                        left: 8,
                        right: 76,
                        top: 0,
                        bottom: 4,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {
                              globalErrors = {};
                              globalErrorStream.add(null);
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 8.0,
                                bottom: 4.0,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.close,
                                    color: Colors.black,
                                    size: 28,
                                  ),
                                  Text(
                                    tr.errorsSheetTitle,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          for (var e in globalErrors.keys) ...[
                            Text(
                              '$e',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            for (var c in globalErrors[e].take(3))
                              Text(
                                '$c',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            if (globalErrors[e].length > 3)
                              Text(
                                tr.errorsSheetOverflowCount(
                                    globalErrors[e].length - 3),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            SizedBox(
                              height: 4,
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                );
              })
        ],
      ),
      floatingActionButton: currentPage == 2
          ? null
          : FloatingActionButton(
              child: Icon(Icons.add),
              onPressed: () async {
                final ctrl = TextEditingController();
                String result = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(tr.addDomainNameDialogTitle),
                    content: Theme(
                      data: Theme.of(context).copyWith(
                          primaryColor: Theme.of(context).accentColor),
                      child: TextField(
                        controller: ctrl,
                        decoration: InputDecoration(
                          labelText: tr.addDomainNameDialogInputLabel,
                          hintText: tr.addDomainNameDialogInputHint,
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (str) => Navigator.of(context).pop(str),
                        autofocus: true,
                        autocorrect: false,
                        keyboardType: TextInputType.url,
                      ),
                    ),
                    actions: <Widget>[
                      FlatButton(
                        onPressed: Navigator.of(context).pop,
                        child: Text(tr.dialogCancel),
                      ),
                      FlatButton(
                        onPressed: () => Navigator.of(context).pop(ctrl.text),
                        child: Text(tr.addDomainNameDialogConfirm),
                      ),
                    ],
                  ),
                );

                if ((result ?? '').isNotEmpty) {
                  await addName(result);
                }
              },
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentPage,
        selectedItemColor: Theme.of(context).accentColor,
        onTap: (index) {
          setState(() {
            currentPage = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            title: Text(tr.navigationAppsPageTitle),
            icon: Icon(Icons.apps),
          ),
          BottomNavigationBarItem(
            title: Text(tr.navigationCollectionsPageTitle),
            icon: Icon(Icons.featured_play_list),
          ),
          BottomNavigationBarItem(
            title: Text(tr.navigationSettingsPageTitle),
            icon: Icon(Icons.settings),
          ),
        ],
      ),
    );
  }

  Future<void> addName(String result) async {
    result = result.toLowerCase();
    print(result);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr.addDomainNameLoadingDialogTitle),
        content: LinearProgressIndicator(),
      ),
      barrierDismissible: false,
    );
    try {
      var res = await checkName(result);
      print('RES $res');
      final type = res['type'];
      res.remove('type');
      print('RES $res');

      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      if (type == 'app') {
        names.put(result, res);
        if (mounted) setState(() {});
        await updateMetadata(res, 'app');
        loadingState[result] = 0;
        addToStream(result);
        if (mounted) setState(() {});
      } else {
        collectionNames.put(result, res);

        await updateAllCollections();
        if (mounted) setState(() {});
      }
    } catch (e, st) {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();

      print(e);
      print(st);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(tr.errorDialogTitle),
          content: Text(e.toString()),
          actions: <Widget>[
            FlatButton(
              onPressed: Navigator.of(context).pop,
              child: Text(tr.errorDialogCloseButton),
            ),
          ],
        ),
      );
    }
  }

  // int currentMetadataUpdateInstances = 0;

  final pool = new Pool(15, timeout: new Duration(seconds: 30));

  Future<void> updateMetadata(Map name, String type) async {
    return pool.withResource(() => updateMetadataInternal(name, type));
  }

  Future<void> updateMetadataInternal(Map name, String type) async {
    bool retry = true;

    while (retry) {
      retry = false;
      var res = await httpClient.get('$skynetPortal/${name['skylink']}');

      if (res.statusCode == 200) {
        //print(res.body);
        final bytes = res.bodyBytes;

        final hash = sha256.convert(bytes);
        /* print(hash);
       print(name['hash']); */
        if (hash.toString() == name['hash']) {
          final doc = loadYaml(utf8.decode(bytes));
          /*          metaLog('loadYaml $doc'); */

          if (type == 'app') {
            final app = App.fromJson(doc.cast<String, dynamic>());

            app.metadataSrcHash = name['hash'];

            apps.put(name['name'], app);

            final a = await DeviceApps.getApp(app.packageName);

            if (a != null) {
              localVersionCodes.put(a.packageName, a.versionCode);
              /*     if (a.versionCode < app.currentVersionCode) {
                //setState(() {});

              } */
            }

            addToStream(name['name']);
          } else if (type == 'collection') {
            final collection = Collection.fromJson(doc.cast<String, dynamic>());

            collection.srcHash = name['hash'];

            collections.put(name['name'], collection);
          }
        } else {
          throw tr.errorMetadataHashMismatch;
        }
      } else if (res.statusCode == 429) {
/*         metaLog('Too many requests'); */
        print('Too many requests');

        await Future.delayed(Duration(seconds: 1));
        retry = true;
      } else {
        throw tr.errorHttpStatusCode(res.statusCode);
      }
      // addToStream(name['name']);
    }
/*     } catch (e, st) {
      currentMetadataUpdateInstances--;
      rethrow;
    }
    currentMetadataUpdateInstances--; */
  }
}

Map<String, Completer<List<String>>> reqs = {};
workTroughReqs() async {
  while (true) {
    //print('walk');
    final keys = List.from(reqs.keys);

    Map<String, Completer<List<String>>> currentBatch = {};
    /*   try { */
    for (var key in keys) {
      currentBatch[key] = reqs[key];
      reqs.remove(key);

      if (currentBatch.length >= 64) {
        checkNameBatch(currentBatch);
        currentBatch = {};
      }
    }
    if (currentBatch.isNotEmpty) {
      checkNameBatch(currentBatch);
    }
    /*   } catch (e, st) {
      print(e);
      print(st);
      print(currentBatch);
    } */

    await Future.delayed(Duration(milliseconds: 100));
  }
}

Future<Map> checkName(String name, {String type}) async {
  //if (reqs.containsKey(name)) return reqs[name].future;

  final completer = Completer<List<String>>();

  reqs[name] = completer;

  final list = await completer.future;
  if (list == null) {
    throw tr.errorDnsRecordNotAvailable;
  }

  for (var answer in list) {
    String data = answer;
    final value = RegExp(r'(?<=skydroid-' +
            (type ?? '(app|collection)') +
            r'=)[0-9]+\+[\w_-]{46}\+\w+')
        .stringMatch(data);

    if (value != null) {
      final parts = value.split('+');

      Map m = {
        'version': int.parse(parts[0]),
        'skylink': parts[1],
        'hash': parts[2],
        'name': name,
      };

      if (type == null) {
        m['type'] =
            RegExp(r'(?<=skydroid-)' + '(app|collection)').stringMatch(data);
      }

      return m;
    }
  }
  throw tr.errorDomainNameHasNoRecord;
}

Future<void> checkNameBatch(Map<String, Completer<List<String>>> batch) async {
  // print('batch ${batch.length}');

  try {
    var res = await httpClient.post(
      '$dnsUrl/multi-dns-query',
      body: json.encode({
        'type': 16,
        'names': batch.keys.toList(),
      }),
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);

      final Map names = data['names'];

      for (var name in names.keys) {
        batch[name]
            .complete(names[name] == null ? null : names[name].cast<String>());
      }
    } else {
      throw Exception(tr.errorHttpStatusCodeMultiDnsQuery(res.statusCode));
    }
  } catch (e, st) {
    // print(e);
    for (var completer in batch.values) {
      completer.completeError(e);
    }
  }
}

/* Future<Map> checkNameNormalDns(String name, {String type}) async {
  final dnsPacket = DnsPacket();
  dnsPacket.questions = [
    DnsQuestion(
      host: name,
    )..type = 16,
  ];

/*   final writer = new RawWriter(capacity: dnsPacket.encodeSelfCapacity());
  dnsPacket.encodeSelf(writer); */
//  return writer.toUint8ListView();


  var res = await http.post(
    '$dnsUrl/dns-query',
    body: dnsPacket.toImmutableBytes(),
    headers: {
      'content-type': 'application/dns-message',
      'user-agent': 'SkyDroid',
    },
  );

  final resDnsPacket = DnsPacket();
  resDnsPacket.decodeSelf(RawReader.withBytes(res.bodyBytes));

  if (res.statusCode == 200) {
    for (var answer in resDnsPacket.answers) {
      String data = String.fromCharCodes(answer.data).trimLeft();
      final value = RegExp(r'(?<=skydroid-' +
              (type ?? '(app|collection)') +
              r'=)[0-9]+\+[\w_-]{46}\+\w+')
          .stringMatch(data);

      if (value != null) {
        final parts = value.split('+');

        Map m = {
          'version': int.parse(parts[0]),
          'skylink': parts[1],
          'hash': parts[2],
          'name': name,
        };

        if (type == null) {
          m['type'] =
              RegExp(r'(?<=skydroid-)' + '(app|collection)').stringMatch(data);
        }

        return m;
      }
    }
    throw Exception('Name has no skydroid record');
  } else {
    print(res.statusCode);
    print(res.body);
    throw Exception('HTTP');
  }
} */

/* Future<Map> checkNameOldJson(String name, {String type}) async {
  var txtRes = await http.get('$dnsUrl/dns-query?name=$name&type=16');

  final txtData = json.decode(txtRes.body);
  //

  if (txtData.containsKey('Answer')) {
    for (var answer in txtData['Answer']) {
      final value = RegExp(r'(?<=skydroid-' +
              (type ?? '(app|collection)') +
              r'=)[0-9]+\+[\w_-]{46}\+\w+')
          .stringMatch(answer['data']);

      if (value != null) {
        final parts = value.split('+');

        Map m = {
          'version': int.parse(parts[0]),
          'skylink': parts[1],
          'hash': parts[2],
          'name': name,
        };

        if (type == null) {
          m['type'] = RegExp(r'(?<=skydroid-)' + '(app|collection)')
              .stringMatch(answer['data']);
        }

        return m;
      }
    }
    throw Exception('Name has no skydroid record');
  } else {
    print(txtRes.statusCode);
    print(txtData);
    throw Exception('Name has no TXT records');
  }
} */
