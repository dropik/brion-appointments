import 'package:flutter/material.dart';

import 'address_field.dart';
import 'date_time_field.dart';
import 'link_generator_form.dart';
import 'phone_number_field.dart';
import 'send_to_whatsapp_button.dart';

class WhatsAppLinkGeneratorScreen extends StatelessWidget {
  const WhatsAppLinkGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Unfocus all fields when tapping outside
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Center(child: Text('БРИОН Встречи')),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LinkGeneratorForm(
            childBuilder: (context, form) => const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                DateTimeField(),
                SizedBox(height: 16),
                PhoneNumberField(),
                SizedBox(height: 16),
                AddressField(),
                SizedBox(height: 32),
                SendToWhatsappButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
