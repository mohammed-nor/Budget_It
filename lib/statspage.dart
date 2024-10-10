import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
//import 'package:google_fonts/google_fonts.dart';
import 'package:budget_calculator/styles.dart';
//import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class Statspage extends StatefulWidget {
  const Statspage({Key? key}) : super(key: key);

  @override
  State<Statspage> createState() => _StatspageState();
}

@override
void initState() async {
  //final double? decimal = prefs.getDouble('decimal');
}

class _StatspageState extends State<Statspage> {
  final prefsdata = Hive.box('data');
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    //print(box.read('quote'));

    num mntincstb1 = prefsdata.get("mntincstb1", defaultValue: 5100);
    num mntincnstb1 = prefsdata.get("mntincnstb1", defaultValue: 2000);
    num mntincstb2 = prefsdata.get("mntincstb2", defaultValue: 5100);
    num mntincnstb2 = prefsdata.get("mntincnstb2", defaultValue: 2000);
    num mntincstb3 = prefsdata.get("mntincstb3", defaultValue: 5100);
    num mntincnstb3 = prefsdata.get("mntincnstb3", defaultValue: 2000);
    num mntincstb4 = prefsdata.get("mntincstb4", defaultValue: 5100);
    num mntincnstb4 = prefsdata.get("mntincnstb4", defaultValue: 2000);
    num mntincstb5 = prefsdata.get("mntincstb5", defaultValue: 5100);
    num mntincnstb5 = prefsdata.get("mntincnstb5", defaultValue: 2000);

    //num totsaving = prefsdata.get("totsaving", defaultValue: 50000);
    //num nownetcredit = prefsdata.get("nownetcredit", defaultValue: 2000);
    //num mntsaving = prefsdata.get("mntsaving", defaultValue: 1000);
    num freemnt = prefsdata.get("freemnt", defaultValue: 5);
    num mntexp = prefsdata.get("mntexp", defaultValue: 2000);
    num annexp = prefsdata.get("annexp", defaultValue: 10000);
    //num mntperexp = prefsdata.get("mntperexp", defaultValue: 10);
    num mntinc = prefsdata.get("mntinc", defaultValue: 5300);
    num mntnstblinc = prefsdata.get("mntnstblinc", defaultValue: 3000);
    num mntperinc = prefsdata.get("mntperinc", defaultValue: 5);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: <Widget>[
          Card(
            elevation: 5,
            margin: const EdgeInsets.all(20),
            color: const Color.fromARGB(253, 223, 135, 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text("مداخيل الأشهر الخمسة الماظية", style: darktextstyle),
                Row(
                  children: [
                    SizedBox(
                      height: size.height * 0.09,
                      width: size.width * 0.20,
                      child: TextFormField(
                        initialValue: mntincnstb1.toString(),
                        decoration: const InputDecoration(
                          label: Text("غير قارة"),
                          //prefixIcon: Icon(Icons.currency_bitcoin_rounded),
                        ),
                        onChanged: (newval) {
                          //box.write('quote', 2);
                          final v = double.tryParse(newval);
                          if (v == null) {
                            setState(() {
                              prefsdata.put("mntincnstb1", 0);
                              mntincnstb1 = prefsdata.get(mntincnstb1.toString());
                              //nownetcredit = 0;
                            });
                          } else {
                            setState(() {
                              prefsdata.put("mntincnstb1".toString(), v);
                              mntincnstb1 = prefsdata.get(mntincnstb1.toString());
                            });
                          }
                        },
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                      ),
                    ),
                    SizedBox(
                      height: size.height * 0.09,
                      width: size.width * 0.20,
                      child: TextFormField(
                        initialValue: mntincstb1.toString(),
                        decoration: const InputDecoration(
                          label: Text("قارة"),
                          //prefixIcon: Icon(Icons.currency_bitcoin_rounded),
                        ),
                        onChanged: (newval) {
                          //box.write('quote', 2);
                          final v = double.tryParse(newval);
                          if (v == null) {
                            setState(() {
                              prefsdata.put("mntincstb1", 0);
                              mntincstb1 = prefsdata.get("mntincstb1".toString());
                              //nownetcredit = 0;
                            });
                          } else {
                            setState(() {
                              prefsdata.put("mntincstb1", v);
                              mntincstb1 = prefsdata.get("mntincstb1".toString());
                            });
                          }
                        },
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                      ),
                    ),
                    Text("الأول", style: darktextstyle)
                  ],
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                ),
                Row(
                  children: [
                    SizedBox(
                      height: size.height * 0.09,
                      width: size.width * 0.20,
                      child: TextFormField(
                        initialValue: mntincnstb2.toString(),
                        decoration: const InputDecoration(
                          label: Text("غير قارة"),
                          //prefixIcon: Icon(Icons.currency_bitcoin_rounded),
                        ),
                        onChanged: (newval) {
                          //box.write('quote', 2);
                          final v = double.tryParse(newval);
                          if (v == null) {
                            setState(() {
                              prefsdata.put("mntincnstb2", 0);
                              mntincnstb2 = prefsdata.get("mntincnstb2".toString());
                              //nownetcredit = 0;
                            });
                          } else {
                            setState(() {
                              prefsdata.put("mntincnstb2".toString(), v);
                              mntincnstb2 = prefsdata.get("mntincnstb2".toString());
                            });
                          }
                        },
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                      ),
                    ),
                    SizedBox(
                      height: size.height * 0.09,
                      width: size.width * 0.20,
                      child: TextFormField(
                        initialValue: mntincstb2.toString(),
                        decoration: const InputDecoration(
                          label: Text("قارة"),
                          //prefixIcon: Icon(Icons.currency_bitcoin_rounded),
                        ),
                        onChanged: (newval) {
                          //box.write('quote', 2);
                          final v = double.tryParse(newval);
                          if (v == null) {
                            setState(() {
                              prefsdata.put("mntincstb2", 0);
                              mntincstb2 = prefsdata.get("mntincstb2".toString());
                              //nownetcredit = 0;
                            });
                          } else {
                            setState(() {
                              prefsdata.put("mntincstb2".toString(), v);
                              mntincstb2 = prefsdata.get("mntincstb2".toString());
                            });
                          }
                        },
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                      ),
                    ),
                    Text("الثاني", style: darktextstyle)
                  ],
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                ),
                Row(
                  children: [
                    SizedBox(
                      height: size.height * 0.09,
                      width: size.width * 0.20,
                      child: TextFormField(
                        initialValue: mntincnstb3.toString(),
                        decoration: const InputDecoration(
                          label: Text("غير قارة"),
                          //prefixIcon: Icon(Icons.currency_bitcoin_rounded),
                        ),
                        onChanged: (newval) {
                          //box.write('quote', 2);
                          final v = double.tryParse(newval);
                          if (v == null) {
                            setState(() {
                              prefsdata.put("mntincnstb3", 0);
                              mntincnstb3 = prefsdata.get("mntincnstb3".toString());
                              //nownetcredit = 0;
                            });
                          } else {
                            setState(() {
                              prefsdata.put("mntincnstb3".toString(), v);
                              mntincnstb3 = prefsdata.get("mntincnstb3".toString());
                            });
                          }
                        },
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                      ),
                    ),
                    SizedBox(
                      height: size.height * 0.09,
                      width: size.width * 0.20,
                      child: TextFormField(
                        initialValue: mntincstb3.toString(),
                        decoration: const InputDecoration(
                          label: Text("قارة"),
                          //prefixIcon: Icon(Icons.currency_bitcoin_rounded),
                        ),
                        onChanged: (newval) {
                          //box.write('quote', 2);
                          final v = double.tryParse(newval);
                          if (v == null) {
                            setState(() {
                              prefsdata.put("mntincstb3", 0);
                              mntincstb3 = prefsdata.get("mntincstb3".toString());
                              //nownetcredit = 0;
                            });
                          } else {
                            setState(() {
                              prefsdata.put("mntincstb3".toString(), v);
                              mntincstb3 = prefsdata.get("mntincstb3".toString());
                            });
                          }
                        },
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                      ),
                    ),
                    Text("الثالث", style: darktextstyle)
                  ],
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                ),
                Row(
                  children: [
                    SizedBox(
                      height: size.height * 0.09,
                      width: size.width * 0.20,
                      child: TextFormField(
                        initialValue: mntincnstb4.toString(),
                        decoration: const InputDecoration(
                          label: Text("غير قارة"),
                          //prefixIcon: Icon(Icons.currency_bitcoin_rounded),
                        ),
                        onChanged: (newval) {
                          //box.write('quote', 2);
                          final v = double.tryParse(newval);
                          if (v == null) {
                            setState(() {
                              prefsdata.put("mntincnstb4", 0);
                              mntincnstb4 = prefsdata.get("mntincnstb4".toString());
                              //nownetcredit = 0;
                            });
                          } else {
                            setState(() {
                              prefsdata.put("mntincnstb4".toString(), v);
                              mntincnstb4 = prefsdata.get("mntincnstb4".toString());
                            });
                          }
                        },
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                      ),
                    ),
                    SizedBox(
                      height: size.height * 0.09,
                      width: size.width * 0.20,
                      child: TextFormField(
                        initialValue: mntincstb4.toString(),
                        decoration: const InputDecoration(
                          label: Text("قارة"),
                          //prefixIcon: Icon(Icons.currency_bitcoin_rounded),
                        ),
                        onChanged: (newval) {
                          //box.write('quote', 2);
                          final v = double.tryParse(newval);
                          if (v == null) {
                            setState(() {
                              prefsdata.put("mntincstb4", 0);
                              mntincstb4 = prefsdata.get("mntincstb4".toString());
                              //nownetcredit = 0;
                            });
                          } else {
                            setState(() {
                              prefsdata.put("mntincstb4".toString(), v);
                              mntincstb4 = prefsdata.get("mntincstb4".toString());
                            });
                          }
                        },
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                      ),
                    ),
                    Text("الرابع", style: darktextstyle)
                  ],
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                ),
                Row(
                  children: [
                    SizedBox(
                      height: size.height * 0.09,
                      width: size.width * 0.20,
                      child: TextFormField(
                        initialValue: mntincnstb5.toString(),
                        decoration: const InputDecoration(
                          label: Text("غير قارة"),
                          //prefixIcon: Icon(Icons.currency_bitcoin_rounded),
                        ),
                        onChanged: (newval) {
                          //box.write('quote', 2);
                          final v = double.tryParse(newval);
                          if (v == null) {
                            setState(() {
                              prefsdata.put("mntincnstb5", 0);
                              mntincnstb5 = prefsdata.get("mntincnstb5".toString());
                              //nownetcredit = 0;
                            });
                          } else {
                            setState(() {
                              prefsdata.put("mntincnstb5".toString(), v);
                              mntincnstb5 = prefsdata.get("mntincnstb5".toString());
                            });
                          }
                        },
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                      ),
                    ),
                    SizedBox(
                      height: size.height * 0.09,
                      width: size.width * 0.20,
                      child: TextFormField(
                        initialValue: mntincstb5.toString(),
                        decoration: const InputDecoration(
                          label: Text("قارة"),
                          //prefixIcon: Icon(Icons.currency_bitcoin_rounded),
                        ),
                        onChanged: (newval) {
                          //box.write('quote', 2);
                          final v = double.tryParse(newval);
                          if (v == null) {
                            setState(() {
                              prefsdata.put("mntincstb5", 0);
                              mntincstb5 = prefsdata.get("mntincstb5".toString());
                              //nownetcredit = 0;
                            });
                          } else {
                            setState(() {
                              prefsdata.put("mntincstb5".toString(), v);
                              mntincstb5 = prefsdata.get("mntincstb5".toString());
                            });
                          }
                        },
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                      ),
                    ),
                    Text("الخامس", style: darktextstyle)
                  ],
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Card(
            elevation: 5,
            margin: const EdgeInsets.all(20),
            color: const Color.fromARGB(251, 0, 192, 42),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        ((mntincnstb1 + mntincnstb2 + mntincnstb3 + mntincnstb4 + mntincnstb5) / 5)
                            .roundToDouble()
                            .toString(),
                        style: darktextstyle),
                    Text(" + ", style: darktextstyle),
                    Text(
                        ((mntincstb1 + mntincstb2 + mntincstb3 + mntincstb4 + mntincstb5) / 5)
                            .roundToDouble()
                            .toString(),
                        style: darktextstyle),
                    Text(" = ", style: darktextstyle),
                    Text(
                        ((mntincstb1 +
                                    mntincstb2 +
                                    mntincstb3 +
                                    mntincstb4 +
                                    mntincstb5 +
                                    mntincnstb1 +
                                    mntincnstb2 +
                                    mntincnstb3 +
                                    mntincnstb4 +
                                    mntincnstb5) /
                                5)
                            .roundToDouble()
                            .toString(),
                        style: darktextstyle),
                    Text("  ", style: darktextstyle),
                    Text("معدل الدخل الشهري", style: darktextstyle),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        "${[
                              mntincnstb1,
                              mntincnstb2,
                              mntincnstb3,
                              mntincnstb4,
                              mntincnstb5
                            ].reduce(max) - (mntincnstb1 + mntincnstb2 + mntincnstb3 + mntincnstb4 + mntincnstb5) / 5}",
                        style: darktextstyle),
                    Text("  ", style: darktextstyle),
                    Text(
                        "${[
                              mntincstb1,
                              mntincstb2,
                              mntincstb3,
                              mntincstb4,
                              mntincstb5,
                            ].reduce(max) - (mntincstb1 + mntincstb2 + mntincstb3 + mntincstb4 + mntincstb5) / 5}",
                        style: darktextstyle),
                    Text("  ", style: darktextstyle),
                    Text("  ", style: darktextstyle),
                    Text("أقصى زيادة عن المتوسط", style: darktextstyle),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        "${-[
                              mntincnstb1,
                              mntincnstb2,
                              mntincnstb3,
                              mntincnstb4,
                              mntincnstb5
                            ].reduce(min) + (mntincnstb1 + mntincnstb2 + mntincnstb3 + mntincnstb4 + mntincnstb5) / 5}",
                        style: darktextstyle),
                    Text("  ", style: darktextstyle),
                    Text(
                        "${-[
                              mntincstb1,
                              mntincstb2,
                              mntincstb3,
                              mntincstb4,
                              mntincstb5,
                            ].reduce(min) + (mntincstb1 + mntincstb2 + mntincstb3 + mntincstb4 + mntincstb5) / 5}",
                        style: darktextstyle),
                    Text("  ", style: darktextstyle),
                    Text("أقصى إنخفاص عن المتوسط", style: darktextstyle),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        "${(0.5 * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12))) / 30.5}",
                        style: darktextstyle),
                    Text("  ", style: darktextstyle),
                    Text("مجموع التشتت عن المتوسط", style: darktextstyle),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        "${([
                              mntincstb1,
                              mntincstb2,
                              mntincstb3,
                              mntincstb4,
                              mntincstb5,
                            ].reduce(max) + [
                              mntincnstb1,
                              mntincnstb2,
                              mntincnstb3,
                              mntincnstb4,
                              mntincnstb5,
                            ].reduce(max) - [
                              mntincstb1,
                              mntincstb2,
                              mntincstb3,
                              mntincstb4,
                              mntincstb5,
                            ].reduce(min) - [
                              mntincnstb1,
                              mntincnstb2,
                              mntincnstb3,
                              mntincnstb4,
                              mntincnstb5,
                            ].reduce(min)) / ([
                              mntincstb1,
                              mntincstb2,
                              mntincstb3,
                              mntincstb4,
                              mntincstb5,
                            ].reduce(max) + [
                              mntincnstb1,
                              mntincnstb2,
                              mntincnstb3,
                              mntincnstb4,
                              mntincnstb5,
                            ].reduce(max) + [
                              mntincstb1,
                              mntincstb2,
                              mntincstb3,
                              mntincstb4,
                              mntincstb5,
                            ].reduce(min) + [
                              mntincnstb1,
                              mntincnstb2,
                              mntincnstb3,
                              mntincnstb4,
                              mntincnstb5,
                            ].reduce(min))}",
                        style: darktextstyle),
                    Text("  ", style: darktextstyle),
                    Text("معدل التشتت", style: darktextstyle),
                  ],
                ),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.all(19.0),
                  child: SfLinearGauge(
                    showTicks: false,
                    axisTrackStyle: const LinearAxisTrackStyle(
                      thickness: 20,
                      edgeStyle: LinearEdgeStyle.bothCurve,
                      gradient: LinearGradient(
                          colors: [Color.fromARGB(255, 157, 0, 185), Color.fromARGB(255, 0, 136, 247)],
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          stops: [0.01, 0.05],
                          tileMode: TileMode.decal),
                    ),
                    animateRange: true,
                    animationDuration: 3000,
                    markerPointers: [
                      LinearShapePointer(
                          value: ([
                                    mntincstb1,
                                    mntincstb2,
                                    mntincstb3,
                                    mntincstb4,
                                    mntincstb5,
                                  ].reduce(max) +
                                  [
                                    mntincnstb1,
                                    mntincnstb2,
                                    mntincnstb3,
                                    mntincnstb4,
                                    mntincnstb5,
                                  ].reduce(max) -
                                  [
                                    mntincstb1,
                                    mntincstb2,
                                    mntincstb3,
                                    mntincstb4,
                                    mntincstb5,
                                  ].reduce(min) -
                                  [
                                    mntincnstb1,
                                    mntincnstb2,
                                    mntincnstb3,
                                    mntincnstb4,
                                    mntincnstb5,
                                  ].reduce(min)) /
                              ([
                                    mntincstb1,
                                    mntincstb2,
                                    mntincstb3,
                                    mntincstb4,
                                    mntincstb5,
                                  ].reduce(max) +
                                  [
                                    mntincnstb1,
                                    mntincnstb2,
                                    mntincnstb3,
                                    mntincnstb4,
                                    mntincnstb5,
                                  ].reduce(max) +
                                  [
                                    mntincstb1,
                                    mntincstb2,
                                    mntincstb3,
                                    mntincstb4,
                                    mntincstb5,
                                  ].reduce(min) +
                                  [
                                    mntincnstb1,
                                    mntincnstb2,
                                    mntincnstb3,
                                    mntincnstb4,
                                    mntincnstb5,
                                  ].reduce(min)) *
                              100,
                          height: 15,
                          width: 15)
                    ],
                    ranges: const [LinearGaugeRange(startValue: 0, endValue: 100)],
                    labelFormatterCallback: (label) {
                      if (label == '0') {
                        return 'ممتاز';
                      }
                      if (label == '10') {
                        return '';
                      }
                      if (label == '20') {
                        return '';
                      }
                      if (label == '30') {
                        return '';
                      }
                      if (label == '40') {
                        return '';
                      }
                      if (label == '60') {
                        return '';
                      }
                      if (label == '70') {
                        return '';
                      }
                      if (label == '80') {
                        return '';
                      }
                      if (label == '90') {
                        return '';
                      }

                      if (label == '50') {
                        return 'جيد';
                      }

                      if (label == '100') {
                        return 'عشوائي';
                      }

                      return label;
                    },
                  ),
                ),
                const SizedBox(height: 20),
                /* RichText(
                        text: TextSpan(style: darkteststyle, children: [
                      TextSpan(text: "مجموع"),
                      TextSpan(text: "  "),
                      TextSpan(
                          text:
                              "${(0.5 * ((mntinc! + mntnstblinc! * (1 - 0.01 * mntperinc!)) * (1 - freemnt! / 12) - (mntexp! + annexp! / 12))) / 30.5}"),
                    ])) */
              ],
            ),
          ),
        ],
      ),
    );

    /* double  tt = ([
              mntincstb1,
              mntincstb2,
              mntincstb3,
              mntincstb4,
              mntincstb5,
            ].reduce(max) +
            [
              mntincnstb1,
              mntincnstb2,
              mntincnstb3,
              mntincnstb4,
              mntincnstb5,
            ].reduce(max) -
            [
              mntincstb1,
              mntincstb2,
              mntincstb3,
              mntincstb4,
              mntincstb5,
            ].reduce(min) -
            [
              mntincnstb1,
              mntincnstb2,
              mntincnstb3,
              mntincnstb4,
              mntincnstb5,
            ].reduce(min)) /
        ([
              mntincstb1,
              mntincstb2,
              mntincstb3,
              mntincstb4,
              mntincstb5,
            ].reduce(max) +
            [
              mntincnstb1,
              mntincnstb2,
              mntincnstb3,
              mntincnstb4,
              mntincnstb5,
            ].reduce(max) +
            [
              mntincstb1,
              mntincstb2,
              mntincstb3,
              mntincstb4,
              mntincstb5,
            ].reduce(min) +
            [
              mntincnstb1,
              mntincnstb2,
              mntincnstb3,
              mntincnstb4,
              mntincnstb5,
            ].reduce(min));
    double ttt(
      double mntincstb1,
      double mntincstb2,
      double mntincstb3,
      double mntincstb4,
      double mntincstb5,
      double mntincnstb1,
      double mntincnstb2,
      double mntincnstb3,
      double mntincnstb4,
      double mntincnstb5,
    ) {
      return ([
                mntincstb1,
                mntincstb2,
                mntincstb3,
                mntincstb4,
                mntincstb5,
              ].reduce(max) +
              [
                mntincnstb1,
                mntincnstb2,
                mntincnstb3,
                mntincnstb4,
                mntincnstb5,
              ].reduce(max) -
              [
                mntincstb1,
                mntincstb2,
                mntincstb3,
                mntincstb4,
                mntincstb5,
              ].reduce(min) -
              [
                mntincnstb1,
                mntincnstb2,
                mntincnstb3,
                mntincnstb4,
                mntincnstb5,
              ].reduce(min)) /
          ([
                mntincstb1,
                mntincstb2,
                mntincstb3,
                mntincstb4,
                mntincstb5,
              ].reduce(max) +
              [
                mntincnstb1,
                mntincnstb2,
                mntincnstb3,
                mntincnstb4,
                mntincnstb5,
              ].reduce(max) +
              [
                mntincstb1,
                mntincstb2,
                mntincstb3,
                mntincstb4,
                mntincstb5,
              ].reduce(min) +
              [
                mntincnstb1,
                mntincnstb2,
                mntincnstb3,
                mntincnstb4,
                mntincnstb5,
              ].reduce(min));
    }
*/
  }
}
