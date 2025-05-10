import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';

void main() async {
  await dotenv.load(); // Load environment variables
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
                _AddressField(form: form),
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
      ),
    );
  }

  String _datetimeToString(DateTime dateTime) {
    return '${DateFormat.yMd(Intl.defaultLocale).format(dateTime)} '
        '${DateFormat.jm(Intl.defaultLocale).format(dateTime)}';
  }
}

class _AddressField extends StatefulWidget {
  const _AddressField({required this.form});

  final FormGroup form;

  @override
  State<_AddressField> createState() => _AddressFieldState();
}

class _AddressFieldState extends State<_AddressField> {
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
