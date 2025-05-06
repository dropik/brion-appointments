import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

void main() {
  Intl.defaultLocale = 'ru_RU'; // Set default locale explicitly
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'БРИОН Встречи',
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('ru', 'RU'), // Add Russian locale
      ],
      home: WhatsAppLinkGenerator(),
    );
  }
}

class WhatsAppLinkGenerator extends StatefulWidget {
  const WhatsAppLinkGenerator({super.key});

  @override
  State<WhatsAppLinkGenerator> createState() => _WhatsAppLinkGeneratorState();
}

class _WhatsAppLinkGeneratorState extends State<WhatsAppLinkGenerator> {
  final FormGroup form = FormGroup({
    'phoneNumber': FormControl<String>(
      validators: [Validators.required],
    ),
    'address': FormControl<String>(
      validators: [Validators.required],
    ),
    'date': FormControl<DateTime>(
      value: DateTime.now(), // Initialize with the current date
      validators: [Validators.required],
    ),
  });

  Future<void> _generateAndOpenWhatsAppLink() async {
    if (!form.valid) {
      form.markAllAsTouched();
      form.markAsDirty();
      return;
    }

    final dateTime = _datetimeToString(form.control('date').value as DateTime);
    final phoneNumber = form.control('phoneNumber').value;
    final address = form.control('address').value;

    final message = 'Ваша встреча:\n'
        'Дата/время: $dateTime\n'
        'Адрес: $address';

    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = Platform.isIOS
        ? "whatsapp://send?phone=$phoneNumber&text=$encodedMessage"
        : "https://wa.me/$phoneNumber?text=$encodedMessage";

    final Uri url = Uri.parse(whatsappUrl);

    final messenger = ScaffoldMessenger.of(context);

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
      form.reset();
      form.control('date').value = DateTime.now(); // Reset the date to now
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Ошибка составления ссылки WhatsApp')),
      );
    }
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: form.control('date').value as DateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: Localizations.localeOf(context), // Use locale for date picker
    );

    if (pickedDate == null) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(form.control('date').value as DateTime),
    );

    if (pickedTime == null) {
      return;
    }

    setState(() {
      form.control('date').value = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('БРИОН Встречи')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ReactiveForm(
          formGroup: form,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ReactiveValueListenableBuilder<DateTime>(
                formControlName: 'date',
                builder: (context, control, child) {
                  return InkWell(
                    onTap: () => _selectDateTime(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Дата',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          Text(_datetimeToString(control.value!)),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              ReactiveTextField<String>(
                formControlName: 'phoneNumber',
                decoration: const InputDecoration(
                  labelText: 'Номер телефона',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validationMessages: {
                  ValidationMessage.required: (_) => 'Введите номер телефона',
                },
              ),
              const SizedBox(height: 16),
              ReactiveTextField<String>(
                formControlName: 'address',
                decoration: const InputDecoration(
                  labelText: 'Адрес',
                  border: OutlineInputBorder(),
                ),
                validationMessages: {
                  ValidationMessage.required: (_) => 'Введите адрес',
                },
              ),
              const SizedBox(height: 32),
              ReactiveFormConsumer(
                builder: (context, form, child) {
                  return ElevatedButton(
                    onPressed: form.valid || form.pristine
                        ? _generateAndOpenWhatsAppLink
                        : null,
                    child: const Text('Отправить в WhatsApp'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _datetimeToString(DateTime dateTime) {
    return '${DateFormat.yMd(Intl.defaultLocale).format(dateTime)} '
        '${DateFormat.jm(Intl.defaultLocale).format(dateTime)}';
  }
}
