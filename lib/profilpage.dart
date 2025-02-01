import 'dart:ffi';
import 'dart:io';
import 'package:budget_calculator/styles and constants.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'package:url_launcher/url_launcher.dart';

class Profilpage extends StatefulWidget {
  Profilpage({Key? key}) : super(key: key);

  @override
  State<Profilpage> createState() => _ProfilpageState();
}

class _ProfilpageState extends State<Profilpage> {
  //Color selectedColor = Colors.white; // Default color

  //String selectedColorName = 'Light';
  @override
  Widget build(BuildContext context) {
    double fontSize1 = prefsdata.get("fontsize1", defaultValue: 15.toDouble());
    double fontSize2 = prefsdata.get("fontsize2", defaultValue: 15.toDouble());
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListView(
        padding: const EdgeInsets.all(2),
        children: <Widget>[
          SizedBox(height: 10),
          SizedBox(height: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                  child: Image.asset('images/1.png', width: 200, height: 200)),
              //clipBehavior: Clip.hardEdge,clipper: ,

              SizedBox(height: 10),
              Text(
                name,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text(
                email,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () async {
                  final Uri url = Uri.parse(githubUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    print("Could not launch $url");
                  }
                },
                icon: Icon(Icons.link),
                label: Text("GitHub"),
              ),
            ],
          ),
          SizedBox(height: 10),
          SizedBox(height: 10),
          Card(
              elevation: 5,
              margin: const EdgeInsets.all(10),
              color: cardcolor,
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 15, right: 15, bottom: 5, top: 5),
                child: Column(
                  children: [
                    SizedBox(height: 10),
                    Text(
                      "الإعدادات",
                      style: darktextstyle,
                      textAlign: TextAlign.right,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.07,
                          width: MediaQuery.of(context).size.width * 0.4,
                          child: SfSlider(
                            min: 10.0,
                            max: 30.0,
                            interval: 5,
                            showTicks: true,
                            showLabels: true,
                            enableTooltip: true,
                            thumbIcon: const Icon(Icons.percent_rounded,
                                color: Colors.blue, size: 14.0),
                            tooltipShape: const SfPaddleTooltipShape(),
                            value: fontSize1,
                            onChanged: (newValue) {
                              setState(() {
                                fontSize1 = newValue;
                                prefsdata.put("fontsize1", newValue);
                              });
                            },
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
                          height: MediaQuery.of(context).size.height * 0.07,
                          width: MediaQuery.of(context).size.width * 0.4,
                          child: SfSlider(
                            min: 10.0,
                            max: 30.0,
                            interval: 5,
                            showTicks: true,
                            showLabels: true,
                            enableTooltip: true,
                            thumbIcon: const Icon(Icons.percent_rounded,
                                color: Colors.blue, size: 14.0),
                            tooltipShape: const SfPaddleTooltipShape(),
                            value: fontSize2,
                            onChanged: (newValue) {
                              setState(() {
                                fontSize2 = newValue;
                                prefsdata.put("fontsize2", newValue);
                              });
                            },
                          ),
                        ),
                        Text(
                          'حجم الخط الثاني',
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
                          height: MediaQuery.of(context).size.height * 0.07,
                          width: MediaQuery.of(context).size.width * 0.4,
                          child: DropdownButton(
                            focusColor: colorMap[selectedColorName],
                            value: selectedColorName,
                            alignment: AlignmentDirectional.centerEnd,
                            isExpanded: true,
                            items: colorMap.keys.map((colorName) {
                              return DropdownMenuItem(
                                //alignment: AlignmentDirectional.centerEnd,
                                value: colorName,
                                child: Text(colorName),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedColorName = newValue!;
                                cardcolor = colorMap[newValue]!;
                              });
                            },
                          ),
                        ),
                        Text(
                          'لون الخلفية',
                          style: darktextstyle,
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ))
        ],
      ),
    );
  }
}
