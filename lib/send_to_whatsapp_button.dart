import 'dart:io';

import 'package:brion_appointment/utils.dart';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:url_launcher/url_launcher.dart';

class SendToWhatsappButton extends StatelessWidget {
  const SendToWhatsappButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ReactiveFormConsumer(
      builder: (context, form, child) {
        final messenger = ScaffoldMessenger.of(context);

        return ElevatedButton(
          onPressed: form.valid || form.pristine
              ? () async => await _generateAndOpenWhatsAppLink(form, messenger)
              : null,
          child: const Text('Отправить в WhatsApp'),
        );
      },
    );
  }

  Future<void> _generateAndOpenWhatsAppLink(FormGroup form, ScaffoldMessengerState messenger) async {
    if (!form.valid) {
      form.markAllAsTouched();
      form.markAsDirty();
      return;
    }

    final dateTime = datetimeToString(form.control('date').value as DateTime);
    final phoneNumber = form.control('phoneNumber').value;
    final address = form.control('address').value;

    final message = 'Ваша встреча:\n'
        'Дата/время: $dateTime\n'
        'Адрес: $address\n\n'
        'Посетите наш сайт: https://brionestate.ru/#wa\n'
        'Если ссылка не активна, добавьте этот номер в контакты.';

    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = Platform.isIOS
        ? "whatsapp://send?phone=$phoneNumber&text=$encodedMessage"
        : "https://wa.me/$phoneNumber?text=$encodedMessage";

    final Uri url = Uri.parse(whatsappUrl);

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
}
