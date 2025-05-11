import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';

class PhoneNumberField extends StatelessWidget {
  const PhoneNumberField({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ReactiveTextField<String>(
      formControlName: 'phoneNumber',
      decoration: const InputDecoration(
        labelText: 'Номер телефона',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.phone,
      validationMessages: {
        ValidationMessage.required: (_) => 'Введите номер телефона',
      },
    );
  }
}
