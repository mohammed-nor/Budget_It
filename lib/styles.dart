import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

final prefsdata = Hive.box('data');

TextStyle darkteststyle2 = TextStyle(
    fontWeight: FontWeight.bold,
    //fontSize: 18,
    fontSize: prefsdata.get("fontsize1", defaultValue: 15.toDouble()),
    color: Colors.white);

TextStyle darktextstyle = GoogleFonts.elMessiri(
    fontWeight: FontWeight.w700,
    fontSize: prefsdata.get("fontsize2", defaultValue: 15.toDouble()),
    color: Colors.white);
