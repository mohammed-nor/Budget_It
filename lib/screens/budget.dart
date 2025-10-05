import 'package:flutter/material.dart';
import 'package:budget_it/services/styles%20and%20constants.dart';
import 'package:hive/hive.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:budget_it/models/budget_history.dart';
import 'package:budget_it/models/upcoming_spending.dart';
import 'package:budget_it/models/unexpected_earning.dart';

class Budgetpage extends StatefulWidget {
  const Budgetpage({super.key});

  @override
  State<Budgetpage> createState() => _BudgetpageState();
}

void initState() {
  cardcolor = prefsdata.get("cardcolor", defaultValue: const Color.fromRGBO(20, 20, 20, 1.0));
}

class _BudgetpageState extends State<Budgetpage> {
  DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  Box<BudgetHistory>? historyBox;
  List<BudgetHistory> budgetHistory = [];

  Box<UpcomingSpending>? upcomingSpendingBox;
  List<UpcomingSpending> upcomingSpendingList = [];

  Box<UnexpectedEarning>? unexpectedEarningsBox;
  List<UnexpectedEarning> unexpectedEarningsList = [];

  @override
  void initState() {
    super.initState();
    cardcolor = prefsdata.get("cardcolor", defaultValue: const Color.fromRGBO(20, 20, 20, 1.0));
    _initHistoryBox();
    _loadBudgetHistory();
    _initUpcomingSpendingBox();
    _initUnexpectedEarningsBox();
  }

  Future<void> _initHistoryBox() async {
    historyBox = await Hive.openBox<BudgetHistory>('budget_history');
  }

  void _loadBudgetHistory() {
    if (historyBox != null && historyBox!.isNotEmpty) {
      budgetHistory = historyBox!.values.toList();
      budgetHistory.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }
  }

  Future<void> _initUpcomingSpendingBox() async {
    upcomingSpendingBox = await Hive.openBox<UpcomingSpending>('upcoming_spending');
    _loadUpcomingSpending();
  }

  void _loadUpcomingSpending() {
    if (upcomingSpendingBox != null && upcomingSpendingBox!.isNotEmpty) {
      setState(() {
        upcomingSpendingList = upcomingSpendingBox!.values.toList();
        upcomingSpendingList.sort((a, b) => a.date.compareTo(b.date));
      });
    }
  }

  Future<void> _initUnexpectedEarningsBox() async {
    unexpectedEarningsBox = await Hive.openBox<UnexpectedEarning>('unexpected_earnings');
    _loadUnexpectedEarnings();
  }

  void _loadUnexpectedEarnings() {
    if (unexpectedEarningsBox != null && unexpectedEarningsBox!.isNotEmpty) {
      setState(() {
        unexpectedEarningsList = unexpectedEarningsBox!.values.toList();
        // Sort by date (closest first)
        unexpectedEarningsList.sort((a, b) => a.date.compareTo(b.date));
      });
    }
  }

  num calculateSpendingBetweenDates(DateTime startDate, DateTime endDate) {
    if (upcomingSpendingBox == null || upcomingSpendingBox!.isEmpty) {
      return 0;
    }

    final spendingEntries =
        upcomingSpendingBox!.values
            .where((entry) => (entry.date.isAfter(startDate) || entry.date.isAtSameMomentAs(startDate)) && (entry.date.isBefore(endDate) || entry.date.isAtSameMomentAs(endDate)))
            .toList();

    if (spendingEntries.isEmpty) {
      return 0;
    }

    num totalSpending = 0;
    for (var entry in spendingEntries) {
      totalSpending += entry.amount;
    }

    return totalSpending;
  }

  num calculateEarningsBetweenDates(DateTime startDate, DateTime endDate) {
    if (unexpectedEarningsBox == null || unexpectedEarningsBox!.isEmpty) {
      return 0;
    }

    final earningEntries =
        unexpectedEarningsBox!.values
            .where((entry) => (entry.date.isAfter(startDate) || entry.date.isAtSameMomentAs(startDate)) && (entry.date.isBefore(endDate) || entry.date.isAtSameMomentAs(endDate)))
            .toList();

    if (earningEntries.isEmpty) {
      return 0;
    }

    num totalEarnings = 0;
    for (var entry in earningEntries) {
      totalEarnings += entry.amount;
    }

    return totalEarnings;
  }

  void _saveCurrentState() {
    if (historyBox != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final todayEntry = historyBox!.values.where((entry) => entry.timestamp.year == today.year && entry.timestamp.month == today.month && entry.timestamp.day == today.day).toList();

      if (todayEntry.isEmpty) {
        final newEntry = BudgetHistory(
          timestamp: today,
          mntsaving: prefsdata.get("mntsaving", defaultValue: 1000),
          freemnt: prefsdata.get("freemnt", defaultValue: 2),
          nownetcredit: prefsdata.get("nownetcredit", defaultValue: 2000),
        );

        historyBox!.add(newEntry);
        budgetHistory = historyBox!.values.toList();
        budgetHistory.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }
    }
  }

  Widget moneyinput(size, boxvariable, boxvariablename, String textlabel) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 7, top: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 50 * fontSize2 / 16,
            width: size.width * 0.17 * fontSize2 / 16,
            child: TextFormField(
              textAlign: TextAlign.center,
              style: darktextstyle.copyWith(fontSize: fontSize2),
              initialValue: boxvariable.toString(),
              decoration: InputDecoration(hintStyle: darktextstyle.copyWith(fontSize: fontSize2), border: OutlineInputBorder(gapPadding: 1)),
              onChanged: (newval) {
                final v = int.tryParse(newval);
                if (v == null) {
                  setState(() {
                    pickStartDate(context);
                    prefsdata.put(boxvariablename, 0);
                    boxvariable = prefsdata.get(boxvariablename.toString());
                    _saveCurrentState();
                  });
                } else {
                  setState(() {
                    pickStartDate(context);
                    prefsdata.put(boxvariablename.toString(), v);
                    boxvariable = prefsdata.get(boxvariablename.toString());
                    _saveCurrentState();
                  });
                }
              },
              keyboardType: TextInputType.number,
            ),
          ),
          Text(textlabel, style: darktextstyle.copyWith(fontSize: fontSize2), textAlign: TextAlign.right),
        ],
      ),
    );
  }

  Widget _buildUpcomingSpendingCard(BuildContext context) {
    return Card(
      elevation: 5,
      color: prefsdata.get("cardcolor", defaultValue: Color.fromRGBO(20, 20, 20, 1.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _showAddSpendingDialog,
                  icon: const Icon(Icons.add),
                  label: Text("", style: darktextstyle.copyWith(fontSize: fontSize1)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 80, 43, 40), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                ),
                Text("مصاريف غير قارة", style: darktextstyle.copyWith(fontSize: fontSize1 * 1.2, fontWeight: FontWeight.bold)),
              ],
            ),

            const SizedBox(height: 16),

            upcomingSpendingList.isEmpty
                ? Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Text("لا توجد مصاريف قادمة مسجلة", style: darktextstyle.copyWith(fontSize: fontSize1, color: Colors.grey[400])))
                : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: upcomingSpendingList.length,
                  itemBuilder: (context, index) {
                    final item = upcomingSpendingList[index];
                    final daysUntil = item.date.difference(DateTime.now()).inDays;

                    return Card(
                      color: const Color.fromRGBO(40, 40, 40, 0.1),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => _deleteUpcomingSpending(item.id),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: const Color.fromRGBO(200, 50, 50, 0.5), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.delete, color: Colors.white, size: 20),
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(item.title, style: darktextstyle.copyWith(fontSize: fontSize1, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${item.date.year}-${item.date.month.toString().padLeft(2, '0')}-${item.date.day.toString().padLeft(2, '0')}",
                                        style: darktextstyle.copyWith(fontSize: fontSize1 * 0.85, color: Colors.grey[400]),
                                      ),
                                      Text(
                                        "${daysUntil < 0 ? 'متأخر بـ ${-daysUntil}' : 'متبقي ${daysUntil}'} يوم",
                                        style: darktextstyle.copyWith(
                                          fontSize: fontSize1 * 0.85,
                                          color:
                                              daysUntil < 0
                                                  ? Colors.red[300]
                                                  : daysUntil < 7
                                                  ? Colors.orange[300]
                                                  : Colors.green[300],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 12),

                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(color: const Color.fromRGBO(30, 30, 30, 1.0), borderRadius: BorderRadius.circular(8)),
                              child: Text("${item.amount} درهم", style: darktextstyle.copyWith(fontSize: fontSize1, fontWeight: FontWeight.bold, color: const Color.fromRGBO(253, 95, 95, 1.0))),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }

  void _showAddSpendingDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          actionsAlignment: MainAxisAlignment.center,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextField(
                  controller: titleController,
                  style: darktextstyle,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(labelText: "عنوان المصروف", labelStyle: darktextstyle.copyWith(color: Colors.grey), border: const OutlineInputBorder()),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: amountController,
                  style: darktextstyle,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: "المبلغ (درهم)", labelStyle: darktextstyle.copyWith(color: Colors.grey), border: const OutlineInputBorder()),
                ),

                const SizedBox(height: 16),

                StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      children: [
                        Text("التاريخ: ${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}", style: darktextstyle),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color.fromRGBO(50, 50, 50, 1.0)),
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Color.fromRGBO(106, 253, 95, 1.0), surface: Color.fromRGBO(30, 30, 30, 1.0))),
                                  child: child!,
                                );
                              },
                            );

                            if (picked != null) {
                              setState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                          child: const Text("اختر التاريخ"),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 253, 95, 95)),

              child: Text("إلغاء", style: darktextstyle.copyWith(color: Colors.black)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color.fromRGBO(106, 253, 95, 1.0)),
              child: Text("إضافة", style: darktextstyle.copyWith(color: Colors.black)),
              onPressed: () {
                if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                  _addUpcomingSpending(titleController.text, num.tryParse(amountController.text) ?? 0, selectedDate);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
          shadowColor: Colors.black54,
        );
      },
    );
  }

  void _addUpcomingSpending(String title, num amount, DateTime date) {
    if (upcomingSpendingBox != null) {
      final newSpending = UpcomingSpending(title: title, amount: amount, date: date);

      upcomingSpendingBox!.add(newSpending);

      setState(() {
        upcomingSpendingList = upcomingSpendingBox!.values.toList();
        upcomingSpendingList.sort((a, b) => a.date.compareTo(b.date));
      });
    }
  }

  void _deleteUpcomingSpending(String id) {
    if (upcomingSpendingBox != null) {
      final int index = upcomingSpendingBox!.values.toList().indexWhere((item) => item.id == id);

      if (index >= 0) {
        upcomingSpendingBox!.deleteAt(index);

        setState(() {
          upcomingSpendingList = upcomingSpendingBox!.values.toList();
          upcomingSpendingList.sort((a, b) => a.date.compareTo(b.date));
        });
      }
    }
  }

  Widget _buildUnexpectedEarningsCard(BuildContext context) {
    return Card(
      elevation: 5,
      color: cardcolor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _showAddEarningDialog,
                  icon: const Icon(Icons.add),
                  label: Text("", style: darktextstyle.copyWith(fontSize: fontSize1)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color.fromRGBO(40, 80, 40, 1.0), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                ),
                Text("مداخيل غير قارة", style: darktextstyle.copyWith(fontSize: fontSize1 * 1.2, fontWeight: FontWeight.bold)),
              ],
            ),

            const SizedBox(height: 16),

            unexpectedEarningsList.isEmpty
                ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text("لا توجد مداخيل غير متوقعة مسجلة", style: darktextstyle.copyWith(fontSize: fontSize1, color: Colors.grey[400])),
                )
                : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: unexpectedEarningsList.length,
                  itemBuilder: (context, index) {
                    final item = unexpectedEarningsList[index];
                    final daysAgo = DateTime.now().difference(item.date).inDays;

                    return Card(
                      color: const Color.fromRGBO(40, 50, 40, 0.2),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Delete button
                            GestureDetector(
                              onTap: () => _deleteUnexpectedEarning(item.id),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: const Color.fromRGBO(200, 50, 50, 0.5), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.delete, color: Colors.white, size: 20),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Item details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(item.title, style: darktextstyle.copyWith(fontSize: fontSize1, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${item.date.year}-${item.date.month.toString().padLeft(2, '0')}-${item.date.day.toString().padLeft(2, '0')}",
                                        style: darktextstyle.copyWith(fontSize: fontSize1 * 0.85, color: Colors.grey[400]),
                                      ),
                                      Text(
                                        daysAgo == 0
                                            ? "اليوم"
                                            : daysAgo == 1
                                            ? "بالأمس"
                                            : "منذ ${daysAgo} يوم",
                                        style: darktextstyle.copyWith(fontSize: fontSize1 * 0.85, color: daysAgo < 3 ? Colors.green[300] : Colors.grey[400]),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Amount
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(color: const Color.fromRGBO(30, 50, 30, 1.0), borderRadius: BorderRadius.circular(8)),
                              child: Text("${item.amount} درهم", style: darktextstyle.copyWith(fontSize: fontSize1, fontWeight: FontWeight.bold, color: const Color.fromRGBO(106, 253, 95, 1.0))),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }

  void _showAddEarningDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromRGBO(30, 40, 30, 1.0),
          title: Text("إضافة دخل غير متوقع", style: darktextstyle.copyWith(fontSize: fontSize1 * 1.2), textAlign: TextAlign.right),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title field
                TextField(
                  controller: titleController,
                  style: darktextstyle,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(labelText: "مصدر الدخل", labelStyle: darktextstyle.copyWith(color: Colors.grey), border: const OutlineInputBorder()),
                ),

                const SizedBox(height: 16),

                // Amount field
                TextField(
                  controller: amountController,
                  style: darktextstyle,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: "المبلغ (درهم)", labelStyle: darktextstyle.copyWith(color: Colors.grey), border: const OutlineInputBorder()),
                ),

                const SizedBox(height: 16),

                // Date picker
                StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      children: [
                        Text("التاريخ: ${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}", style: darktextstyle),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color.fromRGBO(40, 80, 40, 1.0)),
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Color.fromRGBO(106, 253, 95, 1.0), surface: Color.fromRGBO(30, 40, 30, 1.0))),
                                  child: child!,
                                );
                              },
                            );

                            if (picked != null) {
                              setState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                          child: const Text("اختر التاريخ"),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: const Color.fromRGBO(253, 95, 95, 1.0)),
              child: Text("إلغاء", style: darktextstyle),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color.fromRGBO(106, 253, 95, 1.0)),
              child: Text("إضافة", style: darktextstyle.copyWith(color: Colors.black)),
              onPressed: () {
                if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                  _addUnexpectedEarning(titleController.text, num.tryParse(amountController.text) ?? 0, selectedDate);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _addUnexpectedEarning(String title, num amount, DateTime date) {
    if (unexpectedEarningsBox != null) {
      final newEarning = UnexpectedEarning(title: title, amount: amount, date: date);

      unexpectedEarningsBox!.add(newEarning);

      setState(() {
        unexpectedEarningsList = unexpectedEarningsBox!.values.toList();
        unexpectedEarningsList.sort((a, b) => b.date.compareTo(a.date)); // Sort by newest first
      });
    }
  }

  void _deleteUnexpectedEarning(String id) {
    if (unexpectedEarningsBox != null) {
      final int index = unexpectedEarningsBox!.values.toList().indexWhere((item) => item.id == id);

      if (index >= 0) {
        unexpectedEarningsBox!.deleteAt(index);

        setState(() {
          unexpectedEarningsList = unexpectedEarningsBox!.values.toList();
          unexpectedEarningsList.sort((a, b) => b.date.compareTo(a.date));
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double fontSize1 = prefsdata.get("fontsize1", defaultValue: 15.toDouble());
    double fontSize2 = prefsdata.get("fontsize2", defaultValue: 15.toDouble());
    late DateTime NextMonthPaymentDate;
    late DateTime ThisMonthPaymentDate;
    if (today.day >= 30 && today.month != 1) {
      int nextMonth = today.month == 12 ? 1 : today.month + 1;
      int nextYear = today.month == 12 ? today.year + 1 : today.year;
      NextMonthPaymentDate = DateTime(nextYear, nextMonth, 30);
    } else if (today.day >= 30 && today.month != 2 && today.month == 1) {
      int nextMonth = today.month == 12 ? 1 : today.month + 1;
      int nextYear = today.month == 12 ? today.year + 1 : today.year;
      NextMonthPaymentDate = DateTime(nextYear, nextMonth, 28);
    } else if (today.day >= 28 && today.month == 2) {
      int nextMonth = today.month + 1;
      int nextYear = today.year;
      NextMonthPaymentDate = DateTime(nextYear, nextMonth, 30);
    } else if (today.month == 2) {
      NextMonthPaymentDate = DateTime(today.year, today.month, 28);
    } else {
      NextMonthPaymentDate = DateTime(today.year, today.month, 30);
    }

    if (today.day < 30 && today.month <= 12 && today.month > 3) {
      ThisMonthPaymentDate = DateTime(today.year, today.month - 1, 30);
    } else if (today.day < 30 && today.month == 3) {
      ThisMonthPaymentDate = DateTime(today.year, today.month - 1, 28);
    } else if (today.day < 28 && today.month == 2) {
      ThisMonthPaymentDate = DateTime(today.year, today.month - 1, 30);
    } else if (today.day < 30 && today.month == 1) {
      ThisMonthPaymentDate = DateTime(today.year - 1, 12, 30);
    } else {
      ThisMonthPaymentDate = DateTime(today.year, today.month, 30);
    }
    int daysleftInCurrentMonth() {
      DateTime firstDayNextMonth = (today.month < 12) ? DateTime(today.year, today.month + 1, 1) : DateTime(today.year + 1, 1, 1);

      return firstDayNextMonth.subtract(Duration(days: today.day)).day - 1;
    }

    int daysInCurrentMonth = NextMonthPaymentDate.difference(ThisMonthPaymentDate).inDays;
    final size = MediaQuery.of(context).size;
    num totsaving = prefsdata.get("totsaving", defaultValue: 50000);
    num nownetcredit = prefsdata.get("nownetcredit", defaultValue: 2000);
    num nowcredit = prefsdata.get("nowcredit", defaultValue: 2000);
    num mntsaving = prefsdata.get("mntsaving", defaultValue: 1000);
    num freemnt = prefsdata.get("freemnt", defaultValue: 2);
    num mntexp = prefsdata.get("mntexp", defaultValue: 2000);
    num annexp = prefsdata.get("annexp", defaultValue: 7000);
    num mntperexp = prefsdata.get("mntperexp", defaultValue: 15);
    num mntinc = prefsdata.get("mntinc", defaultValue: 4300);
    num mntnstblinc = prefsdata.get("mntnstblinc", defaultValue: 2000);
    num mntperinc = prefsdata.get("mntperinc", defaultValue: 40);
    DateTime startDate = prefsdata.get("startDate", defaultValue: DateTime(2024, 9, 1));

    DateTime ramadane =
        HijriCalendar()
                    .hijriToGregorian(HijriCalendar.now().hYear, 9, 1)
                    .difference(HijriCalendar().hijriToGregorian(HijriCalendar.now().hYear, HijriCalendar.now().hMonth, HijriCalendar.now().hDay))
                    .inDays >
                1
            ? HijriCalendar().hijriToGregorian(HijriCalendar.now().hYear, 9, 1)
            : HijriCalendar().hijriToGregorian(HijriCalendar.now().hYear + 1, 9, 1);
    DateTime aidfitr =
        HijriCalendar()
                    .hijriToGregorian(HijriCalendar.now().hYear, 10, 1)
                    .difference(HijriCalendar().hijriToGregorian(HijriCalendar.now().hYear, HijriCalendar.now().hMonth, HijriCalendar.now().hDay))
                    .inDays >
                1
            ? HijriCalendar().hijriToGregorian(HijriCalendar.now().hYear, 10, 1)
            : HijriCalendar().hijriToGregorian(HijriCalendar.now().hYear + 1, 10, 1);
    DateTime aidfadha =
        HijriCalendar()
                    .hijriToGregorian(HijriCalendar.now().hYear, 12, 10)
                    .difference(HijriCalendar().hijriToGregorian(HijriCalendar.now().hYear, HijriCalendar.now().hMonth, HijriCalendar.now().hDay))
                    .inDays >
                1
            ? HijriCalendar().hijriToGregorian(HijriCalendar.now().hYear, 12, 10)
            : HijriCalendar().hijriToGregorian(HijriCalendar.now().hYear + 1, 12, 10);
    Widget moneyinput(size, boxvariable, boxvariablename, String textlabel) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [const Color.fromARGB(10, 45, 45, 45), const Color.fromARGB(125, 35, 35, 35)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), offset: const Offset(0, 2), blurRadius: 4)],
          border: Border.all(color: const Color.fromRGBO(106, 253, 95, 0.2), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                SizedBox(
                  height: 48 * fontSize2 / 16,
                  width: size.width * 0.2 * fontSize2 / 16,
                  child: TextFormField(
                    textAlign: TextAlign.center,
                    style: darktextstyle.copyWith(fontSize: fontSize2, fontWeight: FontWeight.bold),
                    initialValue: boxvariable.toString(),
                    decoration: InputDecoration(
                      hintStyle: darktextstyle.copyWith(fontSize: fontSize2, color: Colors.grey[600]),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color.fromRGBO(80, 80, 80, 1.0), width: 1)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color.fromRGBO(106, 253, 95, 0.7), width: 1.5)),
                      filled: true,
                      fillColor: const Color.fromRGBO(25, 25, 25, 1.0),
                    ),
                    onChanged: (newval) {
                      final v = int.tryParse(newval);
                      if (v == null) {
                        setState(() {
                          pickStartDate(context);
                          prefsdata.put(boxvariablename, 0);
                          boxvariable = prefsdata.get(boxvariablename.toString());
                          _saveCurrentState();
                        });
                      } else {
                        setState(() {
                          pickStartDate(context);
                          prefsdata.put(boxvariablename.toString(), v);
                          boxvariable = prefsdata.get(boxvariablename.toString());
                          _saveCurrentState();
                        });
                      }
                    },
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[800]!, width: 0.5)),
              child: Text(textlabel, style: darktextstyle.copyWith(fontSize: fontSize2, fontWeight: FontWeight.w500), textAlign: TextAlign.right),
            ),
          ],
        ),
      );
    }

    /*     Widget moneyinput2(size, boxvariable, boxvariablename, String textlabel) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [const Color.fromARGB(10, 45, 45, 45), const Color.fromARGB(125, 35, 35, 35)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), offset: const Offset(0, 2), blurRadius: 4)],
          border: Border.all(color: const Color.fromRGBO(106, 253, 95, 0.2), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                SizedBox(
                  height: 48 * fontSize2 / 16,
                  width: size.width * 0.2 * fontSize2 / 16,
                  child: TextFormField(
                    textAlign: TextAlign.center,
                    style: darktextstyle.copyWith(fontSize: fontSize2, fontWeight: FontWeight.bold),
                    initialValue: boxvariable.toString(),
                    decoration: InputDecoration(
                      hintStyle: darktextstyle.copyWith(fontSize: fontSize2, color: Colors.grey[600]),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color.fromRGBO(80, 80, 80, 1.0), width: 1)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color.fromRGBO(106, 253, 95, 0.7), width: 1.5)),
                      filled: true,
                      fillColor: const Color.fromRGBO(25, 25, 25, 1.0),
                    ),
                    onChanged: (newval) {
                      final v = int.tryParse(newval);
                      if (v == null) {
                        setState(() {
                          pickStartDate(context);
                          prefsdata.put("nownetcredit", 0);
                          boxvariable = prefsdata.get("nownetcredit".toString());
                          prefsdata.put("nowcredit", 0);
                          boxvariable = prefsdata.get("nowcredit".toString());
                          _saveCurrentState();
                        });
                      } else {
                        setState(() {
                          pickStartDate(context);
                          prefsdata.put(
                            "nownetcredit".toString(),
                            v -
                                ((((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / daysInCurrentMonth) * (daysleftInCurrentMonth()))
                                    .round(),
                          );
                          boxvariable = prefsdata.get("nownetcredit".toString());
                          prefsdata.put("nowcredit".toString(), v);
                          boxvariablename = prefsdata.get("nowcredit".toString());
                          _saveCurrentState();
                        });
                      }
                    },
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[800]!, width: 0.5)),
              child: Text(textlabel, style: darktextstyle.copyWith(fontSize: fontSize2, fontWeight: FontWeight.w500), textAlign: TextAlign.right),
            ),
          ],
        ),
      );
    } */

    return Scaffold(
      backgroundColor: Colors.black,
      body: ListView(
        padding: const EdgeInsets.all(7),
        children: <Widget>[
          Card(
            elevation: 2,
            color: cardcolor,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 00, horizontal: 10.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [const Color.fromARGB(10, 45, 45, 45), const Color.fromARGB(125, 35, 35, 35)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), offset: const Offset(0, 3), blurRadius: 6)],
                        border: Border.all(color: const Color.fromRGBO(106, 253, 95, 0.3), width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(color: const Color.fromRGBO(106, 253, 95, 0.15).withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                                      child: const Icon(Icons.account_balance_wallet, color: Color.fromRGBO(106, 253, 95, 1.0), size: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("المبلغ المسموح في اليوم", style: darktextstyle.copyWith(fontSize: fontSize1 * 0.7, color: Colors.grey[400])),
                                        Text(
                                          "${((((((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / daysInCurrentMonth)))).round()} درهم",
                                          style: darktextstyle.copyWith(fontSize: fontSize1 * 1.7, fontWeight: FontWeight.bold, color: const Color.fromRGBO(106, 253, 95, 1.0)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text("المبلغ الإجمالي المتبقي", style: darktextstyle.copyWith(fontSize: fontSize1 * 0.7, color: Colors.grey[400])),
                                    Text(
                                      "${((((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / daysInCurrentMonth) * (daysleftInCurrentMonth() + 1)).round()} درهم",
                                      style: darktextstyle.copyWith(fontSize: fontSize1 * 1.7, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),
                            const Divider(height: 1, color: Color.fromRGBO(80, 80, 80, 0.5)),
                            const SizedBox(height: 14),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                                  decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.withOpacity(0.4))),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today, color: Colors.amber[300], size: 18),
                                      Text("    ${daysleftInCurrentMonth()}", style: darktextstyle.copyWith(fontSize: fontSize1, fontWeight: FontWeight.bold, color: Colors.amber[300])),
                                    ],
                                  ),
                                ),
                                Expanded(child: SizedBox(width: 5)),
                                Text("عدد الأيام المتبقية للأجرة ", style: darktextstyle.copyWith(fontSize: fontSize1)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    TableCalendar(
                      focusedDay: today,
                      rowHeight: 45,
                      firstDay: DateTime(startDate.year, startDate.month, 1),
                      lastDay: DateTime(2050, 12, 31),
                      selectedDayPredicate: (day) => isSameDay(day, today),
                      calendarFormat: CalendarFormat.month,

                      headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                      onDaySelected: _ondayselected,
                      calendarStyle: CalendarStyle(
                        weekNumberTextStyle: const TextStyle(color: Color(0xFFFFFFFF)),
                        weekendTextStyle: TextStyle(fontSize: fontSize1, fontWeight: FontWeight.w900, color: Color(0xFFE82064)),
                        outsideTextStyle: TextStyle(color: const Color(0xFFBEBEBE)),
                        todayDecoration: const BoxDecoration(color: Color(0xFFE696B2), shape: BoxShape.circle),
                        todayTextStyle: TextStyle(color: Color(0xFFFAFAFA), fontSize: fontSize1, fontWeight: FontWeight.w900),
                        selectedDecoration: const BoxDecoration(color: Color(0xFFE82064), shape: BoxShape.circle),
                        selectedTextStyle: TextStyle(color: Color(0xFFFAFAFA), fontSize: fontSize1, fontWeight: FontWeight.w900),
                        defaultTextStyle: TextStyle(fontSize: fontSize1, fontWeight: FontWeight.w900, color: Color(0xFFFFFFFF)),
                      ),
                    ),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0), child: Divider(height: 21)),

                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [const Color.fromARGB(10, 45, 45, 45), const Color.fromARGB(125, 35, 35, 35)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), offset: const Offset(0, 2), blurRadius: 6)],
                        border: Border.all(color: const Color.fromRGBO(106, 253, 95, 0.3), width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: const Color.fromARGB(37, 95, 169, 253), borderRadius: BorderRadius.circular(14)),
                              child: const Icon(Icons.credit_card, color: Color.fromARGB(255, 154, 156, 255), size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text("المبلغ عندك في أول اليوم هو ", style: darktextstyle.copyWith(fontSize: fontSize1, color: Colors.grey[350]), textAlign: TextAlign.right),
                                  const SizedBox(height: 8),
                                  Text(
                                    "${((nowcredit - calculateSpendingBetweenDates(startDate, today) + calculateEarningsBetweenDates(startDate, today) + (daysdiff(startDate, today)) * (-(((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / daysInCurrentMonth)) + count30thsPassed(startDate, today) * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - mntexp))).round()} درهما",
                                    style: darktextstyle.copyWith(fontSize: fontSize1 * 1.2, fontWeight: FontWeight.bold, color: const Color.fromARGB(255, 154, 156, 255)),
                                    textAlign: TextAlign.right,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [const Color.fromARGB(10, 45, 45, 45), const Color.fromARGB(125, 35, 35, 35)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), offset: const Offset(0, 2), blurRadius: 6)],
                        border: Border.all(color: const Color.fromRGBO(106, 253, 95, 0.3), width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: const Color.fromRGBO(106, 253, 95, 0.15), borderRadius: BorderRadius.circular(14)),
                              child: const Icon(Icons.savings, color: Color.fromRGBO(106, 253, 95, 1.0), size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text("المبلغ الذي وفرته", style: darktextstyle.copyWith(fontSize: fontSize1, color: Colors.grey[350]), textAlign: TextAlign.right),
                                  const SizedBox(height: 8),
                                  Text(
                                    "${(nownetcredit - calculateSpendingBetweenDates(startDate, today) + calculateEarningsBetweenDates(startDate, today) + count30thsPassed(startDate, today) * (mntsaving))} درهما",
                                    style: darktextstyle.copyWith(fontSize: fontSize1 * 1.2, fontWeight: FontWeight.bold, color: const Color.fromRGBO(106, 253, 95, 1.0)),
                                    textAlign: TextAlign.right,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [const Color.fromARGB(10, 45, 45, 45), const Color.fromARGB(125, 35, 35, 35)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), offset: const Offset(0, 2), blurRadius: 6)],
                        border: Border.all(
                          color: totsaving - nownetcredit - count30thsPassed(startDate, today) * (mntsaving) > 0 ? const Color.fromRGBO(253, 95, 95, 0.3) : const Color.fromRGBO(106, 253, 95, 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    totsaving - nownetcredit - count30thsPassed(startDate, today) * (mntsaving) > 0
                                        ? const Color.fromRGBO(253, 95, 95, 0.15)
                                        : const Color.fromRGBO(106, 253, 95, 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                totsaving - nownetcredit - count30thsPassed(startDate, today) * (mntsaving) > 0 ? Icons.track_changes : Icons.emoji_events,
                                color:
                                    totsaving - nownetcredit - count30thsPassed(startDate, today) * (mntsaving) > 0 ? const Color.fromRGBO(253, 95, 95, 1.0) : const Color.fromRGBO(106, 253, 95, 1.0),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    totsaving -
                                                calculateSpendingBetweenDates(startDate, today) +
                                                calculateEarningsBetweenDates(startDate, today) -
                                                nownetcredit -
                                                count30thsPassed(startDate, today) * (mntsaving) >
                                            0
                                        ? "المبلغ المتبقي للهدف"
                                        : "تهانينا!",
                                    style: darktextstyle.copyWith(fontSize: fontSize1, color: Colors.grey[350]),
                                    textAlign: TextAlign.right,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    totsaving +
                                                calculateEarningsBetweenDates(startDate, today) -
                                                calculateSpendingBetweenDates(startDate, today) -
                                                nownetcredit -
                                                count30thsPassed(startDate, today) * (mntsaving) >
                                            0
                                        ? "${totsaving - calculateEarningsBetweenDates(startDate, today) + calculateSpendingBetweenDates(startDate, today) - nownetcredit - count30thsPassed(startDate, today) * (mntsaving)} درهما"
                                        : "مبروك، لقد حققت هدفك!",
                                    style: darktextstyle.copyWith(
                                      fontSize: fontSize1 * 1.2,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          totsaving - nownetcredit - count30thsPassed(startDate, today) * (mntsaving) > 0
                                              ? const Color.fromRGBO(253, 95, 95, 1.0)
                                              : const Color.fromRGBO(106, 253, 95, 1.0),
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                clrdinfo(
                  mntinc: mntinc,
                  mntnstblinc: mntnstblinc,
                  mntperinc: mntperinc,
                  freemnt: freemnt,
                  mntexp: mntexp,
                  annexp: annexp,
                  daysInCurrentMonth: daysInCurrentMonth,
                  fontSize1: fontSize1,
                  mntsaving: mntsaving,
                ),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0), child: Divider(height: 21)),

                infocalculated((totsaving - nownetcredit) / mntsaving, "عدد أشهر الإدخار"),
                infocalculated((totsaving - nownetcredit) / (0.5 * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12))), "عدد أشهر الإذخار الأمثل"),
                infocalculated(0.5 * ((mntinc + mntnstblinc) * (1 - freemnt / 12) - (mntexp + annexp / 12)), "أقصى ما يمكن ادخاره"),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0), child: Divider(height: 21)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 25,
                            child: Center(
                              child: Text(
                                "${(((nowcredit - calculateSpendingBetweenDates(startDate, ramadane) + calculateEarningsBetweenDates(startDate, ramadane) + (daysdiff(startDate, ramadane) + 1) * (-(((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / daysInCurrentMonth)) + count30thsPassed(startDate, ramadane) * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - mntexp))).round())}",
                                style: darktextstyle.copyWith(
                                  fontSize: fontSize1,
                                  color:
                                      ((nowcredit -
                                                  calculateSpendingBetweenDates(startDate, ramadane) +
                                                  calculateEarningsBetweenDates(startDate, ramadane) +
                                                  (daysdiff(startDate, ramadane) + 1) *
                                                      (-(((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / daysInCurrentMonth)) +
                                                  count30thsPassed(startDate, ramadane) * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - mntexp)) >
                                              5000
                                          ? const Color(0xF4C3FFBE)
                                          : const Color(0xFAFDBFBF)),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 25,
                            child: Center(
                              child: Text(
                                "${((nowcredit - calculateSpendingBetweenDates(startDate, aidfitr) + calculateEarningsBetweenDates(startDate, aidfitr) + (daysdiff(startDate, aidfitr) + 1) * (-(((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / daysInCurrentMonth)) + count30thsPassed(startDate, aidfitr) * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - mntexp))).round()}",
                                style: darktextstyle.copyWith(
                                  fontSize: fontSize1,
                                  color:
                                      nowcredit -
                                                  calculateSpendingBetweenDates(startDate, aidfitr) +
                                                  calculateEarningsBetweenDates(startDate, aidfitr) +
                                                  (daysdiff(startDate, aidfitr) + 1) *
                                                      (-(((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / daysInCurrentMonth)) +
                                                  count30thsPassed(startDate, aidfitr) * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - mntexp) >
                                              5000
                                          ? const Color(0xF4C3FFBE)
                                          : const Color(0xFAFDBFBF),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 25,
                            child: Center(
                              child: Text(
                                "${((nowcredit - calculateSpendingBetweenDates(startDate, aidfadha) + calculateEarningsBetweenDates(startDate, aidfadha) + (daysdiff(startDate, aidfadha) + 1) * (-(((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / daysInCurrentMonth)) + count30thsPassed(startDate, aidfadha) * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - mntexp))).round()}",
                                style: darktextstyle.copyWith(
                                  fontSize: fontSize1,
                                  color:
                                      nowcredit -
                                                  calculateSpendingBetweenDates(startDate, aidfadha) +
                                                  calculateEarningsBetweenDates(startDate, aidfadha) +
                                                  (daysdiff(startDate, aidfadha) + 1) *
                                                      (-(((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / daysInCurrentMonth)) +
                                                  count30thsPassed(startDate, aidfadha) * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - mntexp) >
                                              6000
                                          ? const Color(0xF4C3FFBE)
                                          : const Color(0xFAFDBFBF),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: 25,
                            child: Center(
                              child: Text(
                                "(${(nownetcredit - calculateSpendingBetweenDates(startDate, ramadane) + calculateEarningsBetweenDates(startDate, ramadane) + count30thsPassed(startDate, ramadane) * (mntsaving))})",
                                style: darktextstyle.copyWith(fontSize: fontSize1),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 25,
                            child: Center(
                              child: Text(
                                "(${(nownetcredit - calculateSpendingBetweenDates(startDate, ramadane) + calculateEarningsBetweenDates(startDate, aidfitr) + count30thsPassed(startDate, aidfitr) * (mntsaving))})",
                                style: darktextstyle.copyWith(fontSize: fontSize1),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 25,
                            child: Center(
                              child: Text(
                                "(${(nownetcredit - calculateSpendingBetweenDates(startDate, aidfadha) + calculateEarningsBetweenDates(startDate, aidfadha) + count30thsPassed(startDate, aidfadha) * (mntsaving))})",
                                style: darktextstyle.copyWith(fontSize: fontSize1),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: 25,
                            child: Center(
                              child: Text(
                                "${ramadane.year}-${ramadane.month.toString().padLeft(2, '0')}-${ramadane.day.toString().padLeft(2, '0')}",
                                style: darktextstyle.copyWith(fontSize: fontSize1),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 25,
                            child: Center(
                              child: Text("${aidfitr.year}-${aidfitr.month.toString().padLeft(2, '0')}-${aidfitr.day.toString().padLeft(2, '0')}", style: darktextstyle.copyWith(fontSize: fontSize1)),
                            ),
                          ),
                          SizedBox(
                            height: 25,
                            child: Center(
                              child: Text(
                                "${aidfadha.year}-${aidfadha.month.toString().padLeft(2, '0')}-${aidfadha.day.toString().padLeft(2, '0')}",
                                style: darktextstyle.copyWith(fontSize: fontSize1),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(height: 25, child: Center(child: Text(":", style: darktextstyle.copyWith(fontSize: fontSize1)))),
                          SizedBox(height: 25, child: Center(child: Text(":", style: darktextstyle.copyWith(fontSize: fontSize1)))),
                          SizedBox(height: 25, child: Center(child: Text(":", style: darktextstyle.copyWith(fontSize: fontSize1)))),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(height: 25, child: Center(child: Text("(يوما", style: darktextstyle.copyWith(fontSize: fontSize1)))),
                          SizedBox(height: 25, child: Center(child: Text("(يوما", style: darktextstyle.copyWith(fontSize: fontSize1)))),
                          SizedBox(height: 25, child: Center(child: Text("(يوما", style: darktextstyle.copyWith(fontSize: fontSize1)))),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(height: 25, child: Center(child: Text("${daysdiff(DateTime.now(), ramadane).toString()})", style: darktextstyle.copyWith(fontSize: fontSize1)))),
                          SizedBox(height: 25, child: Center(child: Text("${daysdiff(DateTime.now(), aidfitr).toString()})", style: darktextstyle.copyWith(fontSize: fontSize1)))),
                          SizedBox(height: 25, child: Center(child: Text("${daysdiff(DateTime.now(), aidfadha).toString()})", style: darktextstyle.copyWith(fontSize: fontSize1)))),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(height: 25, child: Center(child: Text('فاتح رمضان', style: darktextstyle.copyWith(fontSize: fontSize1)))),
                          SizedBox(height: 25, child: Center(child: Text('عيد الفطر', style: darktextstyle.copyWith(fontSize: fontSize1)))),
                          SizedBox(height: 25, child: Center(child: Text('عيد الأضحى', style: darktextstyle.copyWith(fontSize: fontSize1)))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          _buildUpcomingSpendingCard(context),
          _buildUnexpectedEarningsCard(context),
          Card(
            elevation: 2,
            color: cardcolor,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text("تدبير الموارد الخاصة بك", style: darktextstyle.copyWith(fontSize: fontSize1)),
                const SizedBox(height: 20),
                moneyinput(size, totsaving, "totsaving", "المبلغ الإجمالي المراد توفيره"),
                /*
                moneyinput(
                  size,
                  nowcredit,
                  "nowcredit",
                  "المبلغ المتوفر يوم"
                      " ${startDate.year}-${startDate.month}-${startDate.day} "
                      "( ${DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).difference(DateTime(startDate.year, startDate.month, startDate.day)).inDays.toString()} يوم )",
                ),*/
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [const Color.fromARGB(10, 45, 45, 45), const Color.fromARGB(125, 35, 35, 35)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), offset: const Offset(0, 2), blurRadius: 4)],
                    border: Border.all(color: const Color.fromRGBO(106, 253, 95, 0.2), width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            height: 48 * fontSize2 / 16,
                            width: size.width * 0.2 * fontSize2 / 16,
                            child: TextFormField(
                              textAlign: TextAlign.center,
                              style: darktextstyle.copyWith(fontSize: fontSize2, fontWeight: FontWeight.bold),
                              initialValue: nowcredit.toString(),
                              decoration: InputDecoration(
                                hintStyle: darktextstyle.copyWith(fontSize: fontSize2, color: Colors.grey[600]),
                                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color.fromRGBO(80, 80, 80, 1.0), width: 1)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color.fromRGBO(106, 253, 95, 0.7), width: 1.5)),
                                filled: true,
                                fillColor: const Color.fromRGBO(25, 25, 25, 1.0),
                              ),
                              onChanged: (newval) {
                                final v = int.tryParse(newval);
                                if (v == null) {
                                  setState(() {
                                    pickStartDate(context);
                                    prefsdata.put("nownetcredit", 0);
                                    nownetcredit = prefsdata.get("nownetcredit".toString());
                                    prefsdata.put("nowcredit", 0);
                                    nowcredit = prefsdata.get("nowcredit".toString());
                                    _saveCurrentState();
                                  });
                                } else {
                                  setState(() {
                                    pickStartDate(context);
                                    prefsdata.put(
                                      "nownetcredit".toString(),
                                      v -
                                          ((((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / daysInCurrentMonth) *
                                                  (daysleftInCurrentMonth()))
                                              .round(),
                                    );
                                    nownetcredit = prefsdata.get("nownetcredit".toString());
                                    prefsdata.put("nowcredit".toString(), v);
                                    nowcredit = prefsdata.get("nowcredit".toString());
                                    _saveCurrentState();
                                  });
                                }
                              },
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[800]!, width: 0.5)),
                        child: Text(
                          "المبلغ المتوفر يوم"
                          " ${startDate.year}-${startDate.month}-${startDate.day} "
                          "( ${DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).difference(DateTime(startDate.year, startDate.month, startDate.day)).inDays.toString()} يوم )",
                          style: darktextstyle.copyWith(fontSize: fontSize2, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                moneyinput(size, mntsaving, "mntsaving", "المبلغ الشهري المرتقب إدخاره"),

                moneyinput(size, freemnt, "freemnt", "عدد أشهر الراحة السنوية"),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Card(
            elevation: 5,
            color: cardcolor,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text("هيكلة المصاريف الشخصية", style: darktextstyle.copyWith(fontSize: fontSize1)),
                const SizedBox(height: 20),
                moneyinput(size, mntexp, "mntexp", "مصاريف شهرية "),
                moneyinput(size, annexp, "annexp", "مصاريف سنوية"),
                moneyinputslider(size, mntperexp, "mntperexp", "نسبة التغير في الإنفاق        "),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0), child: Divider(height: 21)),
                infocalculated(-(mntsaving - 0.5 * ((mntinc + mntnstblinc) * (1 - freemnt / 12) - (mntexp + annexp / 12))), "فائض / عجز التدبير"),

                Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0), child: Divider(height: 21)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 0.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [const Color.fromARGB(10, 45, 45, 45), const Color.fromARGB(125, 35, 35, 35)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), offset: const Offset(0, 4), blurRadius: 8)],
                      border: Border.all(color: const Color.fromRGBO(106, 253, 95, 0.3), width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: const Color.fromRGBO(106, 253, 95, 0.15), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.timeline, color: Color.fromRGBO(106, 253, 95, 1.0), size: 18),
                              ),
                              const SizedBox(width: 10),
                              Text("مبيان أشهر الإدخار", style: darktextstyle.copyWith(fontSize: fontSize1, fontWeight: FontWeight.bold)),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "${((totsaving - nownetcredit) / mntsaving).toStringAsFixed(1)}",
                                    style: darktextstyle.copyWith(fontSize: fontSize1 * 1.2, fontWeight: FontWeight.bold, color: const Color.fromRGBO(106, 253, 95, 1.0)),
                                  ),
                                  Text("فعلي", style: darktextstyle.copyWith(fontSize: fontSize1 * 0.7, color: Colors.grey[400])),
                                ],
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: Column(
                                  children: [
                                    SfLinearGauge(
                                      interval: 4,
                                      maximum: 24,
                                      showLabels: false,
                                      showAxisTrack: false,
                                      axisTrackStyle: const LinearAxisTrackStyle(
                                        thickness: 12,
                                        edgeStyle: LinearEdgeStyle.bothCurve,
                                        color: Color.fromRGBO(60, 60, 60, 1.0),
                                        borderColor: Color.fromRGBO(80, 80, 80, 1.0),
                                        borderWidth: 1,
                                      ),
                                      ranges: const [LinearGaugeRange(color: Colors.transparent, startValue: 0, endValue: 84)],
                                      markerPointers: [
                                        LinearShapePointer(
                                          value: (totsaving - nownetcredit) / (0.5 * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12))),
                                          shapeType: LinearShapePointerType.diamond,
                                          color: Colors.amber,
                                          position: LinearElementPosition.cross,
                                          width: 12,
                                          height: 12,
                                        ),
                                      ],
                                      barPointers: [
                                        LinearBarPointer(
                                          value: (totsaving - nownetcredit) / mntsaving,
                                          thickness: 12,
                                          edgeStyle: LinearEdgeStyle.bothCurve,
                                          color: const Color.fromRGBO(106, 253, 95, 1.0),
                                          position: LinearElementPosition.cross,
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 5),

                                    // Month scale indicators
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("0", style: darktextstyle.copyWith(fontSize: fontSize1 * 0.7, color: Colors.grey)),
                                        Text("4", style: darktextstyle.copyWith(fontSize: fontSize1 * 0.7, color: Colors.grey)),
                                        Text("8", style: darktextstyle.copyWith(fontSize: fontSize1 * 0.7, color: Colors.grey)),
                                        Text("12", style: darktextstyle.copyWith(fontSize: fontSize1 * 0.7, color: Colors.grey)),
                                        Text("16", style: darktextstyle.copyWith(fontSize: fontSize1 * 0.7, color: Colors.grey)),
                                        Text("20", style: darktextstyle.copyWith(fontSize: fontSize1 * 0.7, color: Colors.grey)),
                                        Text("24", style: darktextstyle.copyWith(fontSize: fontSize1 * 0.7, color: Colors.grey)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 10),

                              // Optimal months indicator
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "${((totsaving - nownetcredit) / (0.5 * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12)))).toStringAsFixed(1)}",
                                    style: darktextstyle.copyWith(fontSize: fontSize1 * 1.2, fontWeight: FontWeight.bold, color: Colors.amber),
                                  ),
                                  Text("أمثل", style: darktextstyle.copyWith(fontSize: fontSize1 * 0.7, color: Colors.grey[400])),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Legend explanation
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(2))),
                                  const SizedBox(width: 5),
                                  Text("المدة المثالية", style: darktextstyle.copyWith(fontSize: fontSize1 * 0.8, color: Colors.grey[400])),
                                ],
                              ),
                              const SizedBox(width: 20),
                              Row(
                                children: [
                                  Container(width: 12, height: 12, decoration: BoxDecoration(color: const Color.fromRGBO(106, 253, 95, 1.0), borderRadius: BorderRadius.circular(2))),
                                  const SizedBox(width: 5),
                                  Text("المدة الفعلية", style: darktextstyle.copyWith(fontSize: fontSize1 * 0.8, color: Colors.grey[400])),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Card(
            elevation: 5,
            color: cardcolor,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text("هيكلة المداخيل الشخصية", style: darktextstyle.copyWith(fontSize: fontSize1)),
                const SizedBox(height: 20),
                moneyinput(size, mntinc, "mntinc", "المداخيل الشهرية القارة"),
                moneyinput(size, mntnstblinc, "mntnstblinc", "مداخيل شهرية غير قارة"),
                moneyinputslider(size, mntperinc, "mntperinc", "نسبة تقلبات المداخيل         "),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0), child: Divider(height: 21)),
                infocalculated(0.5 * ((mntinc + mntnstblinc * (1 + mntperinc * 0.01)) * (12 - freemnt)) - (mntexp * (1 - mntperexp * 0.01) + annexp), "أقصى ما يمكن إدخاره سنويا"),
                infocalculated(0.5 * ((mntinc + mntnstblinc * (1 - mntperinc * 0.01)) * (12 - freemnt)) - (mntexp * (1 + mntperexp * 0.01) + annexp), "أقل ما يمكن إدخاره سنويا"),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget moneyinput2(size, boxvariable, boxvariablename, String textlabel) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 7, top: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: size.width * 0.17 * fontSize2 / 16,
            child: TextFormField(
              textAlign: TextAlign.center,
              style: darktextstyle.copyWith(fontSize: fontSize2),
              initialValue: boxvariable.toString(),
              decoration: InputDecoration(hintStyle: darktextstyle.copyWith(fontSize: fontSize2), border: OutlineInputBorder(gapPadding: 1)),
              onChanged: (newval) {
                final v = int.tryParse(newval);
                if (v == null) {
                  setState(() {
                    pickStartDate(context);
                    prefsdata.put(boxvariablename, 0);
                    boxvariable = prefsdata.get(boxvariablename.toString());
                    print(boxvariable.toString() + boxvariablename.toString());
                    _saveCurrentState();
                  });
                } else {
                  setState(() {
                    pickStartDate(context);
                    prefsdata.put(boxvariablename.toString(), v);
                    boxvariable = prefsdata.get(boxvariablename.toString());
                    print(boxvariable.toString() + boxvariablename.toString());
                    _saveCurrentState();
                  });
                }
              },
              keyboardType: TextInputType.number,
            ),
          ),
          Text(textlabel, style: darktextstyle.copyWith(fontSize: fontSize2), textAlign: TextAlign.right),
        ],
      ),
    );
  }

  int daysdiff(DateTime start, DateTime goal) {
    return -DateTime(start.year, start.month, start.day).difference(DateTime(goal.year, goal.month, goal.day)).inDays;
  }

  Widget moneyinputslider(size, boxvariable, boxvariablename, String textlabel) {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: size.height * 0.07,
            width: size.width * 0.3,
            child: SfSlider(
              min: 0.0,
              max: 100.0,
              interval: 50,
              showTicks: true,
              showLabels: true,
              enableTooltip: true,
              thumbIcon: const Icon(Icons.percent_rounded, color: Colors.blue, size: 14.0),
              tooltipShape: const SfPaddleTooltipShape(),
              value: boxvariable as num,
              onChanged: (dynamic newValue) {
                setState(() {
                  prefsdata.put(boxvariablename.toString(), newValue);
                  boxvariable = prefsdata.get(boxvariablename.toString());
                  print(boxvariable.toString() + boxvariablename.toString());
                  _saveCurrentState();
                });
              },
            ),
          ),
          Text(textlabel, style: darktextstyle.copyWith(fontSize: fontSize2), textAlign: TextAlign.right),
        ],
      ),
    );
  }

  Widget infocalculated(num value, String labelText, {Color? customColor, IconData? icon}) {
    // Determine color based on value (positive = green, negative = red, or use custom)
    final Color valueColor =
        customColor ??
        (value > 0
            ? const Color.fromRGBO(106, 253, 95, 1.0)
            : value < 0
            ? const Color.fromRGBO(253, 95, 95, 1.0)
            : Colors.white);

    // Choose icon if not provided
    final IconData displayIcon =
        icon ??
        (labelText.contains("أشهر")
            ? Icons.calendar_month
            : labelText.contains("ادخار")
            ? Icons.savings
            : labelText.contains("سنوي")
            ? Icons.auto_graph
            : Icons.attach_money);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color.fromRGBO(40, 40, 40, 1.0).withOpacity(0.1), const Color.fromRGBO(30, 30, 30, 1.0).withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), offset: const Offset(0, 2), blurRadius: 4)],
        border: Border.all(color: valueColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side - Value with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: valueColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Icon(displayIcon, color: valueColor, size: 20),
              ),
              const SizedBox(width: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero).animate(animation), child: child));
                },
                child: Text(
                  value.isNaN ? "0" : value.round().toString(),
                  key: ValueKey<String>(value.toString()),
                  style: darktextstyle.copyWith(fontSize: fontSize1, fontWeight: FontWeight.bold, color: valueColor),
                ),
              ),
            ],
          ),

          // Right side - Label
          Text(labelText, style: darktextstyle.copyWith(fontSize: fontSize1, fontWeight: FontWeight.w500), textAlign: TextAlign.right),
        ],
      ),
    );
  }

  int count30thsPassed(DateTime startDate, DateTime endDate) {
    if (startDate.isAfter(endDate)) {
      return 0; // Return 0 if the date range is invalid
    }

    int count = 0;
    DateTime current = DateTime(startDate.year, startDate.month, 28);
    if (current.month == 2) {
      current = DateTime(startDate.year, startDate.month, 28);
    } else {
      current = DateTime(startDate.year, startDate.month, 30);
    }
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      if (current.month == 2) {
        current = DateTime(current.year, 2, 28);
        if (current.isAfter(startDate) && (current.isBefore(endDate) || current.isAtSameMomentAs(endDate))) {
          count++;
        }
      } else {
        count++;
      }
      // Move to the next month's 30th (or closest valid date)
      if (current.month == 1) {
        current = DateTime(current.year, current.month + 1, 28);
      } else {
        current = DateTime(current.year, current.month + 1, 30);
      }
    }

    return count;
  }

  Widget coloredinfocalculated(num value, String labelText, {num? threshold, Color? positiveColor, Color? negativeColor, IconData? icon}) {
    // Set default threshold to 0.5 if not provided
    final num actualThreshold = threshold ?? 0.5;

    // Determine color based on value compared to threshold
    final bool isPositive = value > actualThreshold;
    final Color valueColor =
        isPositive
            ? (positiveColor ?? const Color.fromARGB(255, 127, 255, 131)) // Green for positive/good
            : (negativeColor ?? const Color.fromARGB(255, 216, 19, 1)); // Red for negative/bad

    // Choose icon if not provided
    final IconData displayIcon =
        icon ??
        (labelText.contains("مؤشر")
            ? Icons.speed
            : labelText.contains("نسبة")
            ? Icons.percent
            : isPositive
            ? Icons.trending_up
            : Icons.trending_down);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color.fromRGBO(45, 45, 45, 1.0), const Color.fromRGBO(35, 35, 35, 1.0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), offset: const Offset(0, 2), blurRadius: 4)],
        border: Border.all(color: valueColor.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side - Value with icon and indicator
          Row(
            children: [
              // Icon indicator
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: valueColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: valueColor.withOpacity(0.2), blurRadius: 4, spreadRadius: 1)],
                ),
                child: Icon(displayIcon, color: valueColor, size: 20),
              ),
              const SizedBox(width: 12),

              // Value with animation
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: isPositive ? const Offset(0.0, -0.2) : const Offset(0.0, 0.2),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                      child: child,
                    ),
                  );
                },
                child: Row(
                  key: ValueKey<String>(value.toString()),
                  children: [
                    Text(value.toString(), style: darktextstyle.copyWith(fontSize: fontSize1, fontWeight: FontWeight.bold, color: valueColor)),
                    const SizedBox(width: 5),
                    Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward, color: valueColor, size: 14),
                  ],
                ),
              ),
            ],
          ),

          // Right side - Label with subtle styling
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
            child: Text(labelText, style: darktextstyle.copyWith(fontSize: fontSize1, fontWeight: FontWeight.w500), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Future<void> pickStartDate(BuildContext context) async {
    DateTime startDate = prefsdata.get("startDate", defaultValue: DateTime(2024, 9, 1));
    DateTime pickedDate = DateTime.now();
    setState(() {
      prefsdata.put("startDate", pickedDate);
      startDate = pickedDate;
      debugPrint(startDate.toString());
    });
  }

  void _ondayselected(DateTime day, DateTime focusedDay) {
    setState(() {
      today = day;
    });
  }
}

class clrdinfo extends StatelessWidget {
  const clrdinfo({
    super.key,
    required this.mntinc,
    required this.mntnstblinc,
    required this.mntperinc,
    required this.freemnt,
    required this.mntexp,
    required this.annexp,
    required this.daysInCurrentMonth,
    required this.fontSize1,
    required this.mntsaving,
  });

  final num mntinc;
  final num mntnstblinc;
  final num mntperinc;
  final num freemnt;
  final num mntexp;
  final num annexp;
  final int daysInCurrentMonth;
  final double fontSize1;
  final num mntsaving;

  @override
  Widget build(BuildContext context) {
    // Calculate optimal daily spending
    final optimalDailySpending = ((0.5 * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12)) / daysInCurrentMonth)).round();

    // Calculate ratio for determining status
    final ratio =
        ((0.5 * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12))) / daysInCurrentMonth) /
        ((0.5 * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12)) -
                (mntsaving - 0.5 * ((mntinc + mntnstblinc) * (1 - freemnt / 12) - (mntexp + annexp / 12)))) /
            daysInCurrentMonth);

    // Determine if spending is within optimal range
    final isOptimal = ratio < 0.85;

    // Set color based on status
    final Color valueColor =
        isOptimal
            ? const Color.fromARGB(255, 127, 255, 131) // Green for optimal
            : const Color.fromARGB(255, 216, 19, 1); // Red for non-optimal

    // Choose icon based on status
    final IconData statusIcon = isOptimal ? Icons.check_circle : Icons.warning;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color.fromARGB(10, 45, 45, 45), const Color.fromARGB(125, 35, 35, 35)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: valueColor.withOpacity(0.2), offset: const Offset(0, 3), blurRadius: 6, spreadRadius: 0.5)],
        border: Border.all(color: valueColor.withOpacity(0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side - Value with icon and status
            Row(
              children: [
                // Status icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: valueColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: valueColor.withOpacity(0.2), blurRadius: 8, spreadRadius: 0.5)],
                  ),
                  child: Icon(statusIcon, color: valueColor, size: 24),
                ),

                const SizedBox(width: 14),

                // Value with animation
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 800),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(begin: const Offset(0.0, -0.3), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        optimalDailySpending.toString(),
                        key: ValueKey<String>(optimalDailySpending.toString()),
                        style: darktextstyle.copyWith(fontSize: fontSize1 * 1.4, fontWeight: FontWeight.bold, color: valueColor),
                      ),
                    ),
                    Text(isOptimal ? "ميزانية مثالية" : "تحتاج للتعديل", style: darktextstyle.copyWith(fontSize: fontSize1 * 0.7, color: Colors.grey[400])),
                  ],
                ),
              ],
            ),

            // Right side - Label with subtle styling
            Text("المبلغ الامثل إنفاقه في اليوم", style: darktextstyle.copyWith(fontSize: fontSize1, fontWeight: FontWeight.w500), textAlign: TextAlign.right),
          ],
        ),
      ),
    );
  }
}
