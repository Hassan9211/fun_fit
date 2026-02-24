import 'package:get/get.dart';

class AppShellController extends GetxController {
  AppShellController(int initialIndex) : currentIndex = initialIndex.obs;

  final RxInt currentIndex;

  static const List<String> tabLabels = <String>[
    'Home',
    'Food Log',
    'Challenges',
    'Leaderboard',
    'Guides',
    'Settings',
  ];

  static AppShellController? maybeFind() {
    if (!Get.isRegistered<AppShellController>()) return null;
    return Get.find<AppShellController>();
  }

  static int indexForLabel(String label) {
    final index = tabLabels.indexOf(label);
    return index < 0 ? 0 : index;
  }

  void setIndex(int index) {
    final safe = index.clamp(0, tabLabels.length - 1);
    if (currentIndex.value == safe) return;
    currentIndex.value = safe;
  }

  void selectByLabel(String label) {
    setIndex(indexForLabel(label));
  }
}

