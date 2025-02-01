import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
//import 'package:budget_calculator/budgetpage.dart';
import 'package:budget_calculator/dailypage.dart';
import 'package:budget_calculator/profilpage.dart';
import 'package:budget_calculator/statspage.dart';
import 'package:hive/hive.dart';

final box = GetStorage();
final prefsdata = Hive.box('data');

// double totsaving = 50000;
// double mntsaving = 1000;
// double freemnt = 5;
// double mntexp = 2000;
// double annexp = 10000;
// double mntperexp = 10;
// double mntinc = 5300;
// double mntnstblinc = 3000;
// double mntperinc = 2;
// double nownetcredit = 10000;
// int? vall = 000;
// var val2 = "000";

class Myhome extends StatefulWidget {
  const Myhome({Key? key}) : super(key: key);

  @override
  State<Myhome> createState() => _MyhomeState();
}

void initState() async {
  //final prefs = await SharedPreferences.getInstance();
  //await Hive.openBox("boxname");
}

int pageindex = 2;

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
        backgroundColor:
            prefsdata.get("selectedColor", defaultValue: Colors.black),

        //backgroundColor: ProfilpageState().selectedColor,
        body: getbody(),
        bottomNavigationBar: getfooter(),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            /* await FirebaseFirestore.instance
                .collection('data')
                .add({'timestamp': Timestamp.fromDate(DateTime.now())}); */
            setTabs(2);
          },
          child: const Icon(Icons.query_stats, size: 25),
          backgroundColor: Color(Colors.pink.value),
        ),
        floatingActionButtonLocation:
            FloatingActionButtonLocation.miniCenterDocked,
      ),
    );
  }

  Widget getbody() {
    return IndexedStack(
      index: pageindex,
      children: [
        Statspage(),
        Profilpage(),
        Dailypage(),
      ],
    );
  }

  /// It returns an AnimatedBottomNavigationBar widget with a list of icons, an active color, an active
  /// index, a gap location, a background color, and a notch smoothness
  ///
  /// Returns:
  ///   A widget.
  Widget getfooter() {
    List<IconData> listactions = [
      Icons.calendar_month,
      Icons.settings,
    ];
    return AnimatedBottomNavigationBar(
      icons: listactions,
      activeColor: Colors.pink,
      activeIndex: pageindex,
      onTap: (index) {
        setTabs(index);
      },
      gapLocation: GapLocation.center,
      backgroundColor: Colors.black,
      notchSmoothness: NotchSmoothness.defaultEdge,
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
