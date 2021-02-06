import 'dart:io';

import 'package:flutter_html/flutter_html.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';
import 'package:skydroid/app.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:skydroid/model/app.dart';
import 'package:skydroid/model/collection.dart';
import 'package:skydroid/page/widget/install.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:time_ago_provider/time_ago_provider.dart' as timeAgo;

class FullScreenPage extends StatefulWidget {
  final List<String> images;
  final int index;

  FullScreenPage(this.images, this.index);

  @override
  _FullScreenPageState createState() => _FullScreenPageState();
}

class _FullScreenPageState extends State<FullScreenPage> {
  PageController ctrl;

  @override
  void initState() {
    ctrl = PageController(initialPage: widget.index);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return /* Container(
        child: */
        SafeArea(
      child: Material(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.topRight,
          children: <Widget>[
            PageView(
              controller: ctrl,
              children: <Widget>[
                for (var image in widget.images)
                  Hero(
                    tag: image,
                    child: CachedNetworkImage(
                      imageUrl: resolveLink(image),
                    ),
                  ),
              ],
            ),
            SafeArea(
              child: GestureDetector(
                onTap: Navigator.of(context).pop,
                child: Container(
                  color: Colors.grey.withOpacity(0.7),
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close),
                ),
              ),
            ),
          ],
        ),
      ),
    ) /* ) */;
  }
}

class AppPage extends StatefulWidget {
  final String name;
  final App app;

  AppPage(this.name, this.app);

  @override
  _AppPageState createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  String get name => widget.name;
  App get app => widget.app;
  @override
  void initState() {
    loadVerifications();
    super.initState();
  }

  List<Collection> verifiedBy = [];

  Future loadVerifications() async {
    for (Collection coll in collections.values) {
      final ar =
          coll.apps.firstWhere((ar) => ar.name == name, orElse: () => null);
      if (ar != null) {
        if (ar.verifiedMetadataHashes.contains(app.metadataSrcHash)) {
          verifiedBy.add(coll);
        }
      }
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        /*    leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            // color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: Navigator.of(context).pop,
        ), */
        title: Row(
          children: <Widget>[
            Flexible(
                child: Text(
              name,
              maxLines: 2,
            )),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              Share.share(
                tr.appShareText(
                  app.localizedName,
                  app.localizedSummary,
                  'https://to.skydroid.app/$name',
                ),
              );
            },
          )
        ],
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          ListView(
            physics: BouncingScrollPhysics(),
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 12.0,
                      top: 12.0,
                      right: 4.0,
                      bottom: 4.0,
                    ),
                    child: Hero(
                      tag: 'app-icon-$name',
                      child: (app.icon == null || app.icon.endsWith('.xml'))
                          ? Image.asset(
                              'assets/icon/fallback.png',
                              width: 88,
                              height: 88,
                            )
                          : CachedNetworkImage(
                              imageUrl: resolveLink(app.icon),
                              width: 88,
                              height: 88,
                            ),
                    ),
                  ),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        SizedBox(
                          height: 16,
                        ),
                        Text(
                          app.localizedName,
                          style: TextStyle(
                            fontSize: 24,
                          ),
                        ),
                        Row(
                          children: <Widget>[
                            if (app.authorName != null)
                              Flexible(child: Text(app.authorName)),
                            if (app.authorEmail != null) ...[
                              InkWell(
                                onTap: () {
                                  launch('mailto:${app.authorEmail}');
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: Icon(
                                    Icons.mail,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        Text(
                          (app.categories ?? [])
                              .map((s) => translateCategoryName(s))
                              .join(' • '),
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                        SizedBox(
                          height: 8,
                        ),
                      ],
                    ),
                  ),
                  if (verifiedBy.isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 8,
                          right: 16,
                          top: 16,
                        ),
                        child: InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(
                                  tr.verifiedAppDialogTitle,
                                ),
                                content: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(tr.verifiedAppDialogContentTop + '\n'),
                                    for (var c in verifiedBy)
                                      Text('• ${c.title}'),
                                    Text('\n' +
                                        tr.verifiedAppDialogContentBottom),
                                  ],
                                ),
                                actions: <Widget>[
                                  FlatButton(
                                    onPressed: Navigator.of(context).pop,
                                    child:
                                        Text(tr.verifiedAppDialogCloseButton),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Column(
                            children: <Widget>[
                              Icon(MdiIcons.shieldCheck),
                              SizedBox(
                                height: 2,
                              ),
                              Text(tr.verifiedAppBadgeLabel),
                              Text(verifiedBy.length.toString()),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (app.localizedSummary != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(app.localizedSummary),
                ),
              if (app.localizedWhatsNew != null) ...[
                SizedBox(
                  height: 8,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            tr.appPageWhatsNewTitle,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(app.localizedWhatsNew),
                          if (app.lastUpdated != null)
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                tr.appPageUpdatedTime(
                                  timeAgo.format(
                                    DateTime.fromMillisecondsSinceEpoch(
                                      app.lastUpdated,
                                    ),
                                  ),
                                ),
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              if ((app.localizedPhoneScreenshots ?? []).isNotEmpty) ...[
                SizedBox(
                  height: 4,
                ),
                SizedBox(
                  height: 256,
                  child: ListView(
                    physics: BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    children: <Widget>[
                      SizedBox(
                        width: 8,
                      ),
                      for (var image in app.localizedPhoneScreenshots)
                        Container(
                          constraints: BoxConstraints(minWidth: 120),
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).dividerColor,
                                spreadRadius: 2,
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          margin: const EdgeInsets.all(4.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => FullScreenPage(
                                      app.localizedPhoneScreenshots,
                                      app.localizedPhoneScreenshots
                                          .indexOf(image)),
                                ),
                              );
                            },
                            child: Hero(
                              tag: image,
                              child: CachedNetworkImage(
                                imageUrl: resolveLink(image),
                                placeholder: (context, str) => Material(
                                  color: Theme.of(context).primaryColor,
                                  child: Center(
                                    child: SizedBox(),
                                  ),
                                ),
                                // height: 256,
                              ),
                            ),
                          ),
                        )
                    ],
                  ),
                ),
              ],
              if (app.localizedDescription != null)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child:
                      Html(data: md.markdownToHtml(app.localizedDescription)),
                ),
              if (app.lastUpdated != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Text(
                      tr.appPageUpdatedTime(timeAgo.format(
                          DateTime.fromMillisecondsSinceEpoch(
                              app.lastUpdated))),
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
              if (app.donate != null)
                LinkWidget(tr.appPageLinkDonate, app.donate),
              if (app.bitcoin != null)
                LinkWidget('Bitcoin: ${app.bitcoin}', 'bitcoin:${app.bitcoin}'),
              if (app.litecoin != null)
                LinkWidget(
                    'Litecoin: ${app.litecoin}', 'litecoin:${app.litecoin}'),
              if (app.liberapay != null)
                LinkWidget(
                    'Liberapay', 'https://liberapay.com/${app.liberapay}'),
              if (app.openCollective != null)
                LinkWidget('Open Collective',
                    'https://opencollective.com/${app.openCollective}'),
              if (app.webSite != null)
                LinkWidget(tr.appPageLinkWebsite, app.webSite),
              if (app.sourceCode != null)
                LinkWidget(tr.appPageLinkSourceCode, app.sourceCode),
              if (app.issueTracker != null)
                LinkWidget(tr.appPageLinkIssueTracker, app.issueTracker),
              if (app.translation != null)
                LinkWidget(tr.appPageLinkTranslation, app.translation),
              if (app.changelog != null)
                LinkWidget(tr.appPageLinkChangelog, app.changelog),
              if (app.license != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    tr.appPageLinkLicense(app.license),
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
              SizedBox(
                height: 8,
              ),
              if (app.added != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    tr.appPageAddedTime(
                      DateTime.fromMillisecondsSinceEpoch(app.added)
                          .toIso8601String()
                          .split('T')[0],
                    ),
                  ),
                ),
              SizedBox(
                height: 100,
              ),
            ],
          ),
          InstallWidget(app)
        ],
      ),
    );
  }
}

class LinkWidget extends StatelessWidget {
  final String name;
  final String link;
  LinkWidget(this.name, this.link);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        if (await canLaunch(link)) {
          launch(link);
        } else {
          Share.share(link);
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: <Widget>[
            Icon(Icons.launch),
            SizedBox(
              width: 8,
            ),
            Flexible(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
