import 'package:flutter/material.dart';
import 'package:preferences/preferences.dart';
import 'package:skydroid/app.dart';

typedef ThemedWidgetBuilder = Widget Function(
    BuildContext context, ThemeData data);

typedef ThemeDataWithBrightnessBuilder = ThemeData Function(String theme);

class AppTheme extends StatefulWidget {
  const AppTheme({Key key, this.data, this.themedWidgetBuilder})
      : super(key: key);

  final ThemedWidgetBuilder themedWidgetBuilder;
  final ThemeDataWithBrightnessBuilder data;

  @override
  AppThemeState createState() => AppThemeState();

  static AppThemeState of(BuildContext context) {
    return context.findAncestorStateOfType<AppThemeState>();
  }
}

class AppThemeState extends State<AppTheme> {
  ThemeData _data;

  String _theme;

  ThemeData get data => _data;

  @override
  void initState() {
    super.initState();

    _theme = loadTheme();
    _data = widget.data(_theme);

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _data = widget.data(_theme);
  }

  @override
  void didUpdateWidget(AppTheme oldWidget) {
    super.didUpdateWidget(oldWidget);
    _data = widget.data(_theme);
  }

  void setTheme(String theme) {
    setState(() {
      _data = widget.data(theme);
      _theme = theme;
    });
  }

  void setThemeData(ThemeData data) {
    setState(() {
      _data = data;
    });
  }

  String loadTheme() {
    return PrefService.getString('theme');
  }

  @override
  Widget build(BuildContext context) {
    return widget.themedWidgetBuilder(context, _data);
  }
}
