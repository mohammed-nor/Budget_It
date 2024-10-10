import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
//import 'package:calendar_builder/calendar_builder.dart';

class Budgetpage extends StatelessWidget {
  const Budgetpage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Savings & Expenses Calculator')),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: SavingsForm(),
        ),
      ),
    );
  }
}

class SavingsForm extends StatefulWidget {
  @override
  _SavingsFormState createState() => _SavingsFormState();
}

class _SavingsFormState extends State<SavingsForm> {
  // Fixed expenses and savings
  double _expensesDay1 = 1800;
  double _expensesDay2 = 50;
  double _savingsDay1 = 1000;
  double _incomeDay30 = 6000;

  // Daily expenses
  double _dailyExpense = 30;

  double _requiredAmount = 0.0;
  DateTime _selectedDate = DateTime.now();

  // Method to calculate the required amount
  void _calculateRequiredAmount() {
    int dayOfMonth = _selectedDate.day;
    double totalsvg = 0.0;

    // Check if it's after day 1 to add Day 1 expenses and savings
    if (dayOfMonth >= 1) {
      totalsvg -= _expensesDay1 + _savingsDay1;
    }

    // Check if it's after day 2 to add Day 2 expenses
    if (dayOfMonth >= 2) {
      totalsvg -= _expensesDay2;
    }

    // Add daily expenses for each day
    totalsvg -= _dailyExpense * dayOfMonth;

    // If the selected day is day 30 or beyond, assume the income has come in
    if (dayOfMonth >= 30) {
      totalsvg += _incomeDay30;
    }

    setState(() {
      _requiredAmount = totalsvg;
    });
  }

  // Method to pick a date from the calendar
  Future<void> _pickDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
      lastDate: DateTime(DateTime.now().year, DateTime.now().month, 30),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
      _calculateRequiredAmount(); // Recalculate when date changes
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select a date to calculate:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16.0),
        Row(
          children: [
            Text(
              'Selected Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => _pickDate(context),
              child: Text('Pick Date'),
            ),
          ],
        ),
        SizedBox(height: 16.0),
        Text(
          'Required Amount in Account by Selected Date: \$${_requiredAmount.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
