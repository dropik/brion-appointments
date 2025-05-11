import 'package:brion_appointment/utils.dart';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';

class DateTimeField extends StatelessWidget {
  const DateTimeField({super.key, required this.form});

  final FormGroup form;

  @override
  Widget build(BuildContext context) {
    return ReactiveValueListenableBuilder<DateTime>(
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
                StreamBuilder(
                  initialData: control.value,
                  stream: control.valueChanges,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return Text(datetimeToString(snapshot.data as DateTime));
                    }

                    return const Text('Выберите дату и время');
                  }
                ),
                const Icon(Icons.calendar_today),
              ],
            ),
          ),
        );
      },
    );
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

    form.control('date').value = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }
}
