import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  Intl.defaultLocale = 'ru_RU';

  // Request contacts permission
  final status = await FlutterContacts.requestPermission(readonly: true);
  if (!status) {
    debugPrint('Contacts permission not granted');
  }

  runApp(const App());
}
