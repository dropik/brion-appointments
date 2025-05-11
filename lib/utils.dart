import 'package:intl/intl.dart';

String datetimeToString(DateTime dateTime) {
  return '${DateFormat.yMd(Intl.defaultLocale).format(dateTime)} '
      '${DateFormat.jm(Intl.defaultLocale).format(dateTime)}';
}
