import 'package:hive/hive.dart';

class PrefsService {
  static final _box = Hive.box('data');

  static dynamic get(String key, {dynamic defaultValue}) => _box.get(key, defaultValue: defaultValue);

  static Future<void> put(String key, dynamic value) => _box.put(key, value);
}
