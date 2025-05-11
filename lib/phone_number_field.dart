import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'async_autocomplete.dart';

class PhoneNumberField extends StatelessWidget {
  const PhoneNumberField({super.key});

  Future<List<Suggestion<String>>> _fetchContactSuggestions(String? query) async {
    if (query == null || query.isEmpty) return [];

    final contacts = await FlutterContacts.getContacts(withProperties: true);
    final results = <Suggestion<String>>[];

    for (final contact in contacts) {
      if (contact.phones.isEmpty) continue;
      if (!contact.displayName.toLowerCase().contains(query.toLowerCase())) continue;

      for (final phone in contact.phones) {
        results.add(Suggestion(label: contact.displayName, value: phone.number));
      }
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveFormConsumer(
      builder: (context, form, child) {
        return AsyncAutocomplete<String>(
          control: form.control('phoneNumber') as FormControl<String>,
          source: _fetchContactSuggestions,
          suggestionBuilder: (context, suggestion) => ListTile(
            title: Text(suggestion.label),
            subtitle: Text(suggestion.value),
          ),
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
