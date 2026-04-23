import 'dart:io';

void main() {
  final file = File('lib/screens/budget.dart');
  String content = file.readAsStringSync();

  final startStr = 'children: !isAr';
  int startIdx = content.indexOf(startStr);

  int firstArrayStart = content.indexOf('?', startIdx);
  int firstArrayOpenBracket = content.indexOf('[', firstArrayStart);
  int firstArrayCloseBracket = content.indexOf(']', firstArrayOpenBracket);

  int colonIndex = content.indexOf(':', firstArrayCloseBracket);
  int secondArrayOpenBracket = content.indexOf('[', colonIndex);

  int nextCard = content.indexOf('Card(', secondArrayOpenBracket);
  int secondArrayCloseBracket = content.lastIndexOf(']', nextCard);

  String arrayContent = content.substring(
    firstArrayOpenBracket + 1,
    firstArrayCloseBracket,
  );

  List<String> rawParts = arrayContent.split(RegExp(r'\n\s*Column\('));
  // The first part is empty string or some whitespace depending on where Column( starts.
  List<String> cols = [];
  for (String part in rawParts) {
    if (part.trim().isEmpty) continue;
    cols.add('                            Column(${part.trimRight()}');
  }

  if (cols.length != 7) {
    print(
      "Found ${cols.length} columns, expected 7. Parts found: ${rawParts.length}",
    );
    return;
  }

  List<String> reversedCols = cols.reversed.toList();

  String newChildren =
      'children: [\n${reversedCols.join(',\n')}\n                          ]';

  String newContent =
      content.substring(0, startIdx) +
      newChildren +
      content.substring(secondArrayCloseBracket + 1);

  file.writeAsStringSync(newContent);
  print('Successfully reversed the 7 columns and removed the ternary.');
}
