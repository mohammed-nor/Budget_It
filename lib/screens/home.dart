import 'package:flutter/material.dart';
import 'package:budget_it/screens/budget.dart';
import 'package:budget_it/screens/profil.dart';
import 'package:budget_it/screens/stats.dart';
import 'package:budget_it/screens/wallet.dart';
import 'package:hive/hive.dart';

final prefsdata = Hive.box('data');

class Myhome extends StatefulWidget {
  const Myhome({super.key});

  @override
  State<Myhome> createState() => _MyhomeState();
}

void initState() async {
  //final prefs = await SharedPreferences.getInstance();
  //await Hive.openBox("boxname");
}

int pageindex = 0;

class _MyhomeState extends State<Myhome> {
  final prefsdata = Hive.box('data');
  @override
  /// The function returns a Scaffold widget with a SafeArea widget as its child. The Scaffold widget
  /// has a body, a bottomNavigationBar, and a floatingActionButton. The floatingActionButton has an
  /// onPressed function that calls the setTabs function. The floatingActionButtonLocation is set to
  /// FloatingActionButtonLocation.miniCenterDocked
  ///
  /// Args:
  ///   context (BuildContext): The current context.
  ///
  /// Returns:
  ///   A widget.
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: prefsdata.get("cardcolor", defaultValue: Colors.black) == Color.fromRGBO(89, 89, 89, 1) ? Color.fromRGBO(20, 20, 20, 1.0) : const Color.fromARGB(255, 212, 212, 212),
        body: getbody(),
        bottomNavigationBar: getfooter(),
        /*floatingActionButton: FloatingActionButton(
          onPressed: () async {
            /* await FirebaseFirestore.instance
                .collection('data')
                .add({'timestamp': Timestamp.fromDate(DateTime.now())}); */
            setTabs(2);
          },
          backgroundColor: Colors.pink,
          child: const Icon(Icons.query_stats, size: 25),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.miniEndDocked,*/
      ),
    );
  }

  Widget getbody() {
    return IndexedStack(index: pageindex, children: [Budgetpage(), WalletPage(), Statspage(), Profilpage()]);
  }

  /// It returns an AnimatedBottomNavigationBar widget with a list of icons, an active color, an active
  /// index, a gap location, a background color, and a notch smoothness
  ///
  /// Returns:
  ///   A widget.
  Widget getfooter() {
    List<IconData> listactions = [Icons.account_balance_wallet, Icons.wallet, Icons.calendar_month, Icons.settings_outlined];
    List<String> labels = ["الميزانية", "المحفظة", "الإحصائيات", "الإعدادات"];
    return Theme(
      data: ThemeData(splashColor: Colors.transparent, highlightColor: Colors.transparent),
      child: BottomNavigationBar(
        currentIndex: pageindex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Color.fromARGB(
          255,
          (prefsdata.get("cardcolor", defaultValue: Colors.black).red + 50).clamp(0, 255),
          (prefsdata.get("cardcolor", defaultValue: Colors.black).green + 50).clamp(0, 255),
          (prefsdata.get("cardcolor", defaultValue: Colors.black).blue + 50).clamp(0, 255),
        ),
        unselectedItemColor: const Color.fromARGB(255, 136, 136, 136),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 0,
        iconSize: 26,
        selectedIconTheme: const IconThemeData(size: 30),
        selectedFontSize: 12,
        unselectedFontSize: 10,
        items: List.generate(listactions.length, (index) {
          return BottomNavigationBarItem(
            icon: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: EdgeInsets.only(bottom: pageindex == index ? 4 : 0), child: Icon(listactions[index])),
            label: labels[index],
          );
        }),
        onTap: (index) {
          setTabs(index);
        },
      ),
    );
  }

  void setTabs(int index) {
    setState(() {
      pageindex = index;
    });
  }
}

/// The class is a stateful widget that has a text field and a text widget. The text field has an
/// onChanged function that updates the state of the class. The text widget is updated by the state of
/// the class
