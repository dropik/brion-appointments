import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';

class LinkGeneratorForm extends StatefulWidget {
  const LinkGeneratorForm({super.key, required this.childBuilder});

  final Widget Function(BuildContext context, FormGroup form) childBuilder;

  @override
  State<LinkGeneratorForm> createState() => _LinkGeneratorFormState();
}

class _LinkGeneratorFormState extends State<LinkGeneratorForm> {
  final form = FormGroup({
    'date': FormControl<DateTime>(
      value: DateTime.now(), // Initialize with the current date
      validators: [Validators.required],
    ),
    'phoneNumber': FormControl<String>(
      validators: [Validators.required],
    ),
    'address': FormControl<String>(
      validators: [Validators.required],
    ),
  });

  @override
  void initState() {
    super.initState();

    final phoneControl = form.control('phoneNumber') as FormControl<String>;
    phoneControl.valueChanges.listen((value) {
      if (value != null && value.isNotEmpty) {
        if (value.startsWith('8')) {
          // Remove the leading '8' and add '+7'
          final newValue = '+7${value.substring(1)}';
          form.control('phoneNumber').updateValue(newValue);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveForm(
      formGroup: form,
      child: widget.childBuilder(context, form),
    );
  }
}
