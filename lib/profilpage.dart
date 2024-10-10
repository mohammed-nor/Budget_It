import 'dart:ffi';

import 'package:budget_calculator/styles.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class Profilpage extends StatefulWidget {
  Profilpage({Key? key}) : super(key: key);

  @override
  State<Profilpage> createState() => _ProfilpageState();
}

class _ProfilpageState extends State<Profilpage> {
  static get prefsdata1 => Hive.box('data');
  @override
  Widget build(BuildContext context) {
    num fontsize1 = prefsdata1.get("fontsize1", defaultValue: 30);
    num fontsize2 = prefsdata1.get("fontsize2", defaultValue: 30);
    return MaterialApp(
        home: Scaffold(
            backgroundColor: Color.fromRGBO(4, 5, 5, 0),
            body: Padding(
              padding:
                  const EdgeInsets.only(left: 15, right: 15, bottom: 7, top: 7),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        //height: size.height * 0.07,
                        width: MediaQuery.of(context).size.width * 0.3,
                        child: TextFormField(
                          initialValue: fontsize1.toString(),
                          decoration: const InputDecoration(
                              //prefixIcon: Icon(Icons.currency_bitcoin_rounded),
                              border: OutlineInputBorder(gapPadding: 1)),
                          onChanged: (newval) {
                            //box.write('quote', 2);
                            final v = double.tryParse(newval);
                            if (v == null) {
                              setState(() {
                                prefsdata1.put("fontsize1", 0);
                                fontsize1 = prefsdata1.get("fontsize1");
                                //nownetcredit = 0;
                              });
                            } else {
                              setState(() {
                                prefsdata1.put("fontsize1", v);
                                fontsize1 = prefsdata1.get("fontsize1");
                              });
                            }
                          },
                          keyboardType: TextInputType.number,
                          //maxLength: 10,
                        ),
                      ),
                      Text(
                        ' حجم الخط الأول',
                        style: darktextstyle,
                        textAlign: TextAlign.right,
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        //height: size.height * 0.07,
                        width: MediaQuery.of(context).size.width * 0.3,
                        child: TextFormField(
                          initialValue: fontsize2.toString(),
                          decoration: const InputDecoration(
                              //prefixIcon: Icon(Icons.currency_bitcoin_rounded),
                              border: OutlineInputBorder(gapPadding: 1)),
                          onChanged: (newval) {
                            //box.write('quote', 2);
                            final v = double.tryParse(newval);
                            if (v == null) {
                              setState(() {
                                prefsdata1.put("fontsize2", 0);
                                fontsize2 = prefsdata1.get("fontsize2");
                                //nownetcredit = 0;
                              });
                            } else {
                              setState(() {
                                prefsdata1.put("fontsize2", v);
                                fontsize2 = prefsdata1.get("fontsize2");
                              });
                            }
                          },
                          keyboardType: TextInputType.number,
                          //maxLength: 10,
                        ),
                      ),
                      Text(
                        'حجم الخط الثاني',
                        style: darktextstyle,
                        textAlign: TextAlign.right,
                      )
                    ],
                  ),
                ],
              ),
            )));
  }
}
