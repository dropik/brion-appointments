import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';

class LinkGeneratorForm extends StatefulWidget {
  const LinkGeneratorForm({super.key, required this.childBuilder});

  final Widget Function(FormGroup form) childBuilder;

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
  Widget build(BuildContext context) {
    return ReactiveForm(
      formGroup: form,
      child: widget.childBuilder(form),
    );
  }
}
