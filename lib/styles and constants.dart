import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

final prefsdata = Hive.box('data');
double fontSize1 = prefsdata.get("fontsize1", defaultValue: 15.toDouble());
double fontSize2 = prefsdata.get("fontsize2", defaultValue: 15.toDouble());
TextStyle darkteststyle2 = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: fontSize1.toDouble(),
    color: Colors.white);

TextStyle darktextstyle = GoogleFonts.elMessiri(
    fontWeight: FontWeight.w700,
    fontSize: fontSize2.toDouble(),
    color: Colors.white);

final Map<String, Color> colorMap = {
  'Red': const Color.fromRGBO(255, 0, 0, 0.1843137254901961),
  'Green': const Color.fromRGBO(0, 143, 3, 1.0),
  'Blue': const Color.fromRGBO(97, 134, 255, 0.1843137254901961),
  'Dark': const Color.fromRGBO(14, 14, 14, 0.1843137254901961),
  'Light': const Color.fromRGBO(20, 20, 20, 1.0),
};

Color selectedColor =
    prefsdata.get("selectedColor", defaultValue: Colors.white);

String selectedColorName =
    prefsdata.get("selectedColorName", defaultValue: 'Dark');

Color cardcolor =
    prefsdata.get("cardcolor", defaultValue: const Color.fromRGBO(20, 20, 20, 1.0));

const String name = "Mohammed NOR";
const String email = "nour1608@gmail.com";
const String githubUrl = "https://github.com/mohammed-nor/";
const String profileImageUrl =
    "https://avatars.githubusercontent.com/u/44341598?v=4"; // Replace with actual image URL
