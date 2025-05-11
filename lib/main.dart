import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';

void main() async {
  await dotenv.load();
  Intl.defaultLocale = 'ru_RU';
  runApp(const App());
}
