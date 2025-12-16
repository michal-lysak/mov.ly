import 'package:hive/hive.dart';

import '../../../presentation/widgets/cached_section.dart';

class SectionsCache {
  static const boxName = 'sections';

  static Future<void> saveSection(
      String sectionKey,
      List<int> movieIds,
      ) async {
    final box = await Hive.openBox(boxName);
    await box.put(
      sectionKey,
      CachedSection(
        movieIds: movieIds,
        cachedAt: DateTime.now().millisecondsSinceEpoch,
      ).toJson(),
    );
  }

  static Future<CachedSection?> loadSection(String sectionKey) async {
    final box = await Hive.openBox(boxName);
    final data = box.get(sectionKey);
    if (data == null) return null;
    return CachedSection.fromJson(Map<String, dynamic>.from(data));
  }

}
