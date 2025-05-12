import 'dart:io';

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

    final dateTime = form.control('date').value as DateTime;
    final year = dateTime.year.toString();
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final phoneNumber = form.control('phoneNumber').value;
    final address = form.control('address').value;

    final message =
        '*Запланированная встреча*\n'
        '\n'
        'Дата: _$day/$month/${year}_\n'
        'Время: _$hour:${minute}_\n'
        'Адрес: _${address}_\n'
        '\n'
        'В случае если у Вас изменятся планы, сообщите, пожалуйста, об этом здесь.\n'
        '\n'
        'Все предлагаемые объекты и услуги Вы можете увидеть, посетив наш сайт:\n'
        'https://brionestate.ru/#wa\n'
        '\n'
        'Если ссылка не активна, добавьте, пожалуйста, этот номер в контакты.\n'
        '\n'
        '_С уважением, Елена_';

    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = Platform.isIOS
        ? "whatsapp://send?phone=$phoneNumber&text=$encodedMessage"
        : "https://wa.me/$phoneNumber?text=$encodedMessage";

    final Uri url = Uri.parse(whatsappUrl);

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
      form.reset();
      form.control('date').value = DateTime.now();
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Ошибка составления ссылки WhatsApp')),
      );
    }
  }
}
