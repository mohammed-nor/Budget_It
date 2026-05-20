import 'package:budget_it/services/styles%20and%20constants.dart';
import 'package:flutter/material.dart';
import 'package:budget_it/screens/budget.dart';
import 'package:budget_it/screens/profil.dart';
import 'package:budget_it/screens/stats.dart';
import 'package:budget_it/screens/wallet.dart';
import 'package:budget_it/services/notification_service.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:upgrader/upgrader.dart';

final prefsdata = Hive.box('data');

class Myhome extends StatefulWidget {
  const Myhome({super.key});

  @override
  State<Myhome> createState() => _MyhomeState();
}

class _MyhomeState extends State<Myhome> {
  final prefsdata = Hive.box('data');
  int pageindex = 0;

  @override
  void initState() {
    super.initState();
    // Request permissions after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final box = Hive.box('data');
      final notifEnabled = box.get(kNotifEnabled, defaultValue: true) as bool;
      if (notifEnabled) {
        await NotificationService.instance.requestPermissions();
      }

      // Check for updates
      _checkForUpdate();
    });
  }

  Future<void> _checkForUpdate() async {
    final upgrader = Upgrader();
    await upgrader.initialize();

    if (upgrader.shouldDisplayUpgrade()) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "new_version_available".tr,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blueAccent,
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: "update".tr,
            textColor: Colors.yellow,
            onPressed: () {
              upgrader.sendUserToAppStore();
            },
          ),
        ),
      );
    }
  }

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
    List<IconData> listactions = [
      Icons.account_balance_wallet,
      Icons.wallet,
      Icons.calendar_month,
      Icons.settings_outlined,
    ];
    List<String> labels = ["budget".tr, "wallet".tr, "stats".tr, "settings".tr];
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color.fromRGBO(20, 20, 20, 1.0),
        body: getbody(),
        bottomNavigationBar: Theme(
          data: ThemeData(
            splashColor: Colors.black,
            highlightColor: Colors.transparent,
          ),
          child: ValueListenableBuilder(
            valueListenable: prefsdata.listenable(
              keys: ['fontsize1', 'cardcolor'],
            ),
            builder: (context, box, child) {
              return Container(
                decoration: BoxDecoration(
                  /* boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(1),
                      blurRadius: 5,
                      spreadRadius: 1,
                      offset: const Offset(0, -6),
                    ),
                  ], */
                  border: Border.all(
                    color: Colors.green.withOpacity(0.15),
                    width: 1.5,
                  ),
                ),
                child: BottomNavigationBar(
                  currentIndex: pageindex,
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.black,
                  selectedItemColor: Color.fromARGB(
                    255,
                    (prefsdata
                                .get("cardcolor", defaultValue: Colors.black)
                                .red +
                            50)
                        .clamp(0, 255),
                    (prefsdata
                                .get("cardcolor", defaultValue: Colors.black)
                                .green +
                            50)
                        .clamp(0, 255),
                    (prefsdata
                                .get("cardcolor", defaultValue: Colors.black)
                                .blue +
                            50)
                        .clamp(0, 255),
                  ),
                  unselectedItemColor: const Color.fromARGB(255, 136, 136, 136),
                  showSelectedLabels: true,
                  showUnselectedLabels: true,
                  elevation: 0,
                  iconSize: 26,
                  selectedIconTheme: const IconThemeData(size: 30),
                  selectedFontSize: fontSize1 - 3,
                  unselectedFontSize: fontSize1 - 3,
                  items: List.generate(listactions.length, (index) {
                    return BottomNavigationBarItem(
                      icon: ExcludeSemantics(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.only(
                            bottom: pageindex == index ? 4 : 0,
                          ),
                          child: Icon(listactions[index]),
                        ),
                      ),
                      label: labels[index],
                    );
                  }),
                  onTap: (index) {
                    setTabs(index);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget getbody() {
    return IndexedStack(
      index: pageindex,
      children: [
        ExcludeSemantics(excluding: pageindex != 0, child: Budgetpage()),
        ExcludeSemantics(excluding: pageindex != 1, child: WalletPage()),
        ExcludeSemantics(excluding: pageindex != 2, child: Statspage()),
        ExcludeSemantics(excluding: pageindex != 3, child: Profilpage()),
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
      Icons.account_balance_wallet,
      Icons.wallet,
      Icons.calendar_month,
      Icons.settings_outlined,
    ];
    List<String> labels = ["budget".tr, "wallet".tr, "stats".tr, "settings".tr];
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Theme(
        data: ThemeData(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ValueListenableBuilder(
          valueListenable: prefsdata.listenable(
            keys: ['fontsize1', 'cardcolor'],
          ),
          builder: (context, box, child) {
            return BottomNavigationBar(
              currentIndex: pageindex,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              selectedItemColor: Color.fromARGB(
                255,
                (prefsdata.get("cardcolor", defaultValue: Colors.black).red +
                        50)
                    .clamp(0, 255),
                (prefsdata.get("cardcolor", defaultValue: Colors.black).green +
                        50)
                    .clamp(0, 255),
                (prefsdata.get("cardcolor", defaultValue: Colors.black).blue +
                        50)
                    .clamp(0, 255),
              ),
              unselectedItemColor: const Color.fromARGB(255, 136, 136, 136),
              showSelectedLabels: true,
              showUnselectedLabels: true,
              elevation: 0,
              iconSize: 26,
              selectedIconTheme: const IconThemeData(size: 30),
              selectedFontSize: fontSize1 - 3,
              unselectedFontSize: fontSize1 - 5,
              items: List.generate(listactions.length, (index) {
                return BottomNavigationBarItem(
                  icon: ExcludeSemantics(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.only(
                        bottom: pageindex == index ? 4 : 0,
                      ),
                      child: Icon(listactions[index]),
                    ),
                  ),
                  label: labels[index],
                );
              }),
              onTap: (index) {
                setTabs(index);
              },
            );
          },
        ),
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
