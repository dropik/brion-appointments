import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:http/http.dart' as http;

import 'async_autocomplete.dart';

class AddressField extends StatelessWidget {
  const AddressField({super.key});

  Future<List<Suggestion<String>>> _fetchAddressSuggestions(String? query) async {
    if (query == null) return [];
    if (query.isEmpty) return [];
    if (query.length < 3) return []; // Minimum length for suggestions
    final apiKey = dotenv.env['YANDEX_API_KEY']; // Load API key from .env
    final url = Uri.parse(
        'https://suggest-maps.yandex.ru/v1/suggest?text=$query&lang=ru_RU&apikey=$apiKey&results=5');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final suggestions = List<Suggestion<String>>.from(data['results'].map((item) {
          final title = item['title']['text'];
          final subtitle = item['subtitle']['text'];
          final suggestion = '$title, $subtitle';
          return Suggestion(label: suggestion, value: suggestion);
        }));
        return suggestions;
      }
    } catch (e) {
      debugPrint('Error fetching suggestions: $e');
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveFormConsumer(
      builder: (context, form, child) {
        final theme = Theme.of(context);
        final control = form.control('address') as FormControl<String>;

        return AsyncAutocomplete<String>(
          control: control,
          source: _fetchAddressSuggestions,
          suggestionBuilder: (context, suggestion) => ListTile(
            title: Text(suggestion.label, style: theme.textTheme.bodyMedium),
          ),
          controlBuilder: (context, focusNode) => ReactiveTextField<String>(
            formControlName: 'address',
            focusNode: focusNode, // Attach the FocusNode
            decoration: InputDecoration(
              labelText: 'Адрес',
              border: const OutlineInputBorder(),
              suffixIcon: StreamBuilder(
                  stream: control.valueChanges,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
                      return IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          control.reset();
                          control.markAsTouched();
                        },
                      );
                    }

                    return const SizedBox.shrink();
                  }
              ),
            ),
            validationMessages: {
              ValidationMessage.required: (_) => 'Введите адрес',
            },
          ),
        );
      }
    );
  }
}
