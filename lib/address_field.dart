import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:http/http.dart' as http;

class AddressField extends StatefulWidget {
  const AddressField({super.key, required this.form});

  final FormGroup form;

  @override
  State<AddressField> createState() => _AddressFieldState();
}

class _AddressFieldState extends State<AddressField> {
  final FocusNode _addressFocusNode = FocusNode(); // FocusNode for address field
  final LayerLink _layerLink = LayerLink(); // Link for overlay positioning
  OverlayEntry? _overlayEntry;
  bool _isAddressFocused = false;
  List<String> _lastSuggestions = [];

  final StreamController<List<String>> _suggestionsStreamController =
  StreamController<List<String>>.broadcast();

  Timer? _debounce; // Timer for debounce

  @override
  void initState() {
    super.initState();
    _addressFocusNode.addListener(() {
      setState(() {
        _isAddressFocused = _addressFocusNode.hasFocus;
        if (_isAddressFocused) {
          _showOverlay();
        } else {
          _removeOverlay();
        }
      });
    });

    widget.form.control('address').valueChanges.listen((query) {
      if (_debounce?.isActive ?? false) _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () async {
        final suggestions = await _fetchAddressSuggestions(query);
        _lastSuggestions = suggestions;
        _suggestionsStreamController.add(suggestions);
      });
    });
  }

  @override
  void dispose() {
    _removeOverlay();
    _addressFocusNode.dispose();
    _suggestionsStreamController.close();
    _debounce?.cancel(); // Cancel the debounce timer
    super.dispose();
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final theme = Theme.of(context);

        return Positioned(
          width: MediaQuery.of(context).size.width - 32, // Match field width
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 56), // Position below the text field
            child: Material(
              type: MaterialType.card,
              elevation: 4,
              child: StreamBuilder<List<String>>(
                initialData: _lastSuggestions,
                stream: _suggestionsStreamController.stream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 200,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final suggestion = snapshot.data![index];
                        return ListTile(
                          title: Text(suggestion, style: theme.textTheme.bodyMedium),
                          onTap: () {
                            widget.form.control('address').updateValue(suggestion);
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<List<String>> _fetchAddressSuggestions(String? query) async {
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
        final suggestions = List<String>.from(data['results'].map((item) {
          final title = item['title']['text'];
          final subtitle = item['subtitle']['text'];
          return '$title, $subtitle';
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
    return CompositedTransformTarget(
      link: _layerLink,
      child: ReactiveTextField<String>(
        formControlName: 'address',
        focusNode: _addressFocusNode, // Attach the FocusNode
        decoration: InputDecoration(
          labelText: 'Адрес',
          border: const OutlineInputBorder(),
          suffixIcon: StreamBuilder(
              stream: widget.form.control('address').valueChanges,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
                  return IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      widget.form.control('address').reset(); // Clear the field
                    },
                  );
                }

                return const SizedBox.shrink(); // No icon if the field is empty
              }
          ),
        ),
        validationMessages: {
          ValidationMessage.required: (_) => 'Введите адрес',
        },
      ),
    );
  }
}
