import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:skydroid/app.dart';
import 'package:skydroid/main.dart';
import 'package:preferences/preferences.dart';
import 'package:skydroid/model/collection.dart';

class CollectionsPage extends StatefulWidget {
  final Function refreshCallback;

  CollectionsPage({this.refreshCallback});

  @override
  _CollectionsPageState createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {
  var reccs = [
    CollectionRecommendation(
      name: 'redsolver',
      title: 'red\'s collection',
      description:
          'This collection contains every app available via SkyDroid that I\'m aware of. Some apps are verified.',
    ),
    CollectionRecommendation(
      name: 'papagei',
      title: 'F-Droid Collection',
      description:
          'This collection contains the latest apps bridged from the F-Droid Main Repo.',
    ),
  ]; 

  @override
  Widget build(BuildContext context) {
    final recommendations = reccs
        .where((element) => !collectionNames.containsKey(element.name))
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        globalErrors = {};
        globalErrorStream.add(null);
        await widget.refreshCallback();
        setState(() {});
      },
      child: ListView(
        padding: const EdgeInsets.only(
          top: 8,
          bottom: 8,
        ),
        children: <Widget>[
          /*          PreferenceTitle('Your Collections'),
          PreferenceTitle('New Collections'), */
          for (var colName in collectionNames.keys)
            () {
              if (!collections.containsKey(colName)) {
                return ListTile(
                  title: Text('$colName'),
                  subtitle: Text('Loading...'),
                );
              }
              final Collection c = collections.get(colName);
              return ListTile(
                onLongPress: () {
                  removeName(colName);
                },
                title: Text('${c.title} ($colName) • ${c.apps.length} Apps'),
                subtitle: Text(c.description),
                leading: Container(
                  width: 56,
                  alignment: Alignment.topCenter,
                  child: CachedNetworkImage(imageUrl: resolveLink(c.icon)),
                ),
              );
            }(),
          if (recommendations.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: <Widget>[
                      Text(
                        'Some recommendations to get you started',
                        style: TextStyle(fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      for (var rec in recommendations)
                        ListTile(
                          title: Text(rec.title),
                          subtitle: Text(rec.description),
                          trailing: IconButton(
                              icon: Icon(
                                Icons.add_circle_outline,
                                color: Theme.of(context).accentColor,
                              ),
                              onPressed: () async {
                                collectionNames
                                    .put(rec.name, {'name': rec.name});

                                await widget.refreshCallback();
                                if (mounted) setState(() {});
                              }),
                        ),
                    ],
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }

  removeName(String name) async {
    var res = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('Remove collection?'),
              content: Text(
                  'Do you really want to remove the collection "$name"? This action doesn\'t affect any apps added through this collection.'),
              actions: <Widget>[
                FlatButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                FlatButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: Text('Remove'),
                ),
              ],
            ));

    if (res == true) {
      if (collections.containsKey(name)) await collections.delete(name);
      await collectionNames.delete(name);
      setState(() {});
    }
  }
}

class CollectionRecommendation {
  String name;
  String title;
  String description;

  CollectionRecommendation({this.name, this.title, this.description});
}
