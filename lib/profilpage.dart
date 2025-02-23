import 'package:budget_it/styles and constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'package:url_launcher/url_launcher.dart';

class Profilpage extends StatefulWidget {
  const Profilpage({super.key});

  @override
  State<Profilpage> createState() => _ProfilpageState();
}

class _ProfilpageState extends State<Profilpage> {
  //Color selectedColor = Colors.white; // Default color

  TextStyle darkteststyle2 = TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize1, color: Colors.white);

  TextStyle darktextstyle = GoogleFonts.elMessiri(fontWeight: FontWeight.w700, fontSize: fontSize2.toDouble(), color: Colors.white);
  //String selectedColorName = 'Light';
  @override
  Widget build(BuildContext context) {
    double fontSize1 = prefsdata.get("fontsize1", defaultValue: 15.toDouble());
    double fontSize2 = prefsdata.get("fontsize2", defaultValue: 15.toDouble());
    TextStyle darkteststyle2 = TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize1, color: Colors.white);

    TextStyle darktextstyle = GoogleFonts.elMessiri(fontWeight: FontWeight.w700, fontSize: fontSize2.toDouble(), color: Colors.white);

    return Scaffold(
      backgroundColor: Colors.black,
      body: ListView(
        padding: const EdgeInsets.all(7),
        children: <Widget>[
          Card(
            elevation: 5,
            //margin: const EdgeInsets.all(10),
            color: cardcolor,
            child: Padding(
              padding: const EdgeInsets.only(left: 15, right: 15, bottom: 5, top: 5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  const SizedBox(height: 10),
                  Text("هذا التطبيق تم تطويره من طرف المطور", style: darktextstyle.copyWith(fontSize: fontSize1, color: Colors.grey.shade500), textAlign: TextAlign.center),
                  ClipOval(child: Image.asset('images/1.png', width: 200, height: 200)),

                  //clipBehavior: Clip.hardEdge,clipper: ,
                  const SizedBox(height: 10),
                  const Text(name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(email, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final Uri url = Uri.parse(githubUrl);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      } else {
                        print("Could not launch $url");
                      }
                    },
                    icon: const Icon(Icons.link),
                    label: const Text("GitHub"),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "هذا التطبيق هدفه مساعدتك على تسيير ماليتك ، دعمك في الادخار و اعطائك فكرة عن تدبيرك المالي ، لكن عليك استحضار التوازن المالي و المنهج الرباني في التدبير من خلال قوله تعالى",
                    style: darktextstyle.copyWith(fontSize: fontSize1 - 2, color: Colors.grey.shade300),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  Text(
                    "وَلَا تَجْعَلْ يَدَكَ مَغْلُولَةً إِلَىٰ عُنُقِكَ وَلَا تَبْسُطْهَا كُلَّ ٱلْبَسْطِ فَتَقْعُدَ مَلُومًا مَّحْسُورًا",
                    style: darktextstyle.copyWith(fontSize: fontSize1 + 2, color: Colors.green),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  Text("صدق الله العظيم", style: darktextstyle.copyWith(fontSize: fontSize1, color: Colors.grey.shade300), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
          Card(
            elevation: 5,
            //margin: const EdgeInsets.all(10),
            color: cardcolor,
            child: Padding(
              padding: const EdgeInsets.only(left: 15, right: 15, bottom: 5, top: 5),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Text("الإعدادات", style: darktextstyle, textAlign: TextAlign.right),
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
                          stepSize: 0.1,
                          showTicks: true,
                          showLabels: true,
                          enableTooltip: true,
                          thumbIcon: const Icon(Icons.percent_rounded, color: Colors.blue, size: 14.0),
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
                      Text(' حجم خط المعلومات', style: darktextstyle, textAlign: TextAlign.right),
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
                          thumbIcon: const Icon(Icons.percent_rounded, color: Colors.blue, size: 14.0),
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
                      Text('حجم خط الإعدادات', style: darktextstyle, textAlign: TextAlign.right),
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
                          items:
                              colorMap.keys.map((colorName) {
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
                              prefsdata.put("cardcolor", colorMap[newValue]!);
                            });
                          },
                        ),
                      ),
                      Text('لون الخلفية', style: darktextstyle, textAlign: TextAlign.right),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
