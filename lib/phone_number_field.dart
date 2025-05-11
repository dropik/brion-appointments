import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'async_autocomplete.dart';

class PhoneNumberField extends StatelessWidget {
  const PhoneNumberField({super.key});

  Future<List<Suggestion<String>>> _fetchContactSuggestions(String? query) async {
    if (query == null || query.isEmpty) return [];

    final contacts = await FlutterContacts.getContacts(withProperties: true);
    return contacts
        .where((contact) => contact.displayName.contains(RegExp(RegExp.escape(query), caseSensitive: false)) && contact.phones.isNotEmpty)
        .map((contact) {
          final phone = contact.phones.first.number;
          final name = contact.displayName;
          return Suggestion(label: name, value: phone);
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveFormConsumer(
      builder: (context, form, child) {
        return AsyncAutocomplete<String>(
          control: form.control('phoneNumber') as FormControl<String>,
          source: _fetchContactSuggestions,
          controlBuilder: (context, focusNode) {
            return ReactiveTextField<String>(
              formControlName: 'phoneNumber',
              focusNode: focusNode,
              decoration: const InputDecoration(
                labelText: 'Номер телефона',
                border: OutlineInputBorder(),
              ),
              validationMessages: {
                ValidationMessage.required: (_) => 'Введите номер телефона',
              },
            );
          },
        );
      }
    );
  }
}
