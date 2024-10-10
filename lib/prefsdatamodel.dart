import 'package:hive/hive.dart';
part 'prefsdatamodel.g.dart';

@HiveType(typeId: 0)
// run in terminal : flutter packages pub run  build_runner build
class PrefsDataStore extends HiveObject {}
