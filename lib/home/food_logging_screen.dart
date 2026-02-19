import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../widget/animated_reveal.dart';
import '../widget/app_colors.dart';
import '../widget/getx.dart';
import '../widget/home_bottom_nav.dart';

class FoodLoggingScreen extends StatelessWidget {
  const FoodLoggingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final selectedMeal = args is Map && args['meal'] is String
        ? args['meal'] as String
        : 'Breakfast';
    return _FoodLogView(initialMeal: selectedMeal);
  }
}

class AddMealScreen extends StatelessWidget {
  const AddMealScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FoodLoggingScreen();
  }
}

class _FoodLogView extends StatefulWidget {
  final String initialMeal;

  const _FoodLogView({required this.initialMeal});

  @override
  State<_FoodLogView> createState() => _FoodLogViewState();
}

class _FoodLogViewState extends State<_FoodLogView> {
  static const _meals = ['Breakfast', 'Lunch', 'Dinner', 'Snacks', 'Water'];
  String _selectedMeal = 'Breakfast';

  final Map<String, List<_FoodItem>> _mealData = {
    'Breakfast': [
      const _FoodItem(
        name: 'Greek Yogurt Bowl',
        calories: 220,
        protein: 17,
        carbs: 21,
        fat: 8,
      ),
    ],
    'Lunch': [
      const _FoodItem(
        name: 'Grilled Chicken Salad',
        calories: 340,
        protein: 32,
        carbs: 11,
        fat: 16,
      ),
    ],
    'Dinner': [],
    'Snacks': [],
    'Water': [],
  };

  @override
  void initState() {
    super.initState();
    _selectedMeal = _meals.contains(widget.initialMeal)
        ? widget.initialMeal
        : 'Breakfast';
  }

  int get _totalCalories =>
      _mealData.values.expand((e) => e).fold(0, (s, i) => s + i.calories);
  int get _totalProtein =>
      _mealData.values.expand((e) => e).fold(0, (s, i) => s + i.protein);
  int get _totalCarbs =>
      _mealData.values.expand((e) => e).fold(0, (s, i) => s + i.carbs);
  int get _totalFat =>
      _mealData.values.expand((e) => e).fold(0, (s, i) => s + i.fat);

  Future<void> _showAddFoodDialog() async {
    final nameCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();
    final carbsCtrl = TextEditingController();
    final fatCtrl = TextEditingController();
    String meal = _selectedMeal;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Food'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _field(nameCtrl, 'Food name'),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: meal,
                  items: _meals
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => meal = v ?? meal,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Meal',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _field(calCtrl, 'Calories')),
                    const SizedBox(width: 10),
                    Expanded(child: _field(proteinCtrl, 'Protein (g)')),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _field(carbsCtrl, 'Carbs (g)')),
                    const SizedBox(width: 10),
                    Expanded(child: _field(fatCtrl, 'Fat (g)')),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add Food'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    final item = _FoodItem(
      name: nameCtrl.text.trim().isEmpty ? 'Custom Food' : nameCtrl.text.trim(),
      calories: int.tryParse(calCtrl.text) ?? 0,
      protein: int.tryParse(proteinCtrl.text) ?? 0,
      carbs: int.tryParse(carbsCtrl.text) ?? 0,
      fat: int.tryParse(fatCtrl.text) ?? 0,
    );
    setState(() => _mealData[meal]!.add(item));
  }

  Future<void> _showAddRecipeDialog() async {
    final nameCtrl = TextEditingController();
    final ingredientsCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();
    final carbsCtrl = TextEditingController();
    final fatCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Recipe'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _field(nameCtrl, 'Recipe Name'),
                const SizedBox(height: 10),
                _field(ingredientsCtrl, 'Ingredients', maxLines: 3),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _field(calCtrl, 'Calories')),
                    const SizedBox(width: 10),
                    Expanded(child: _field(proteinCtrl, 'Protein (g)')),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _field(carbsCtrl, 'Carbs (g)')),
                    const SizedBox(width: 10),
                    Expanded(child: _field(fatCtrl, 'Fat (g)')),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save Recipe'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    final item = _FoodItem(
      name: nameCtrl.text.trim().isEmpty
          ? 'Custom Recipe'
          : nameCtrl.text.trim(),
      calories: int.tryParse(calCtrl.text) ?? 0,
      protein: int.tryParse(proteinCtrl.text) ?? 0,
      carbs: int.tryParse(carbsCtrl.text) ?? 0,
      fat: int.tryParse(fatCtrl.text) ?? 0,
    );
    setState(() => _mealData[_selectedMeal]!.add(item));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1100;
    final isTablet = width >= 700 && width < 1100;
    final hPadding = isDesktop
        ? 32.0
        : isTablet
        ? 24.0
        : 16.0;
    final contentMaxWidth = isDesktop
        ? 1020.0
        : isTablet
        ? 860.0
        : width;
    final chipHeight = isDesktop
        ? 42.0
        : isTablet
        ? 40.0
        : 36.0;
    final summaryGridCount = isDesktop ? 4 : 2;
    final summaryAspect = isDesktop
        ? 1.8
        : isTablet
        ? 1.55
        : 1.45;
    final summaryValueSize = isDesktop
        ? 26.0
        : isTablet
        ? 24.0
        : 22.0;
    final summaryLabelSize = isDesktop
        ? 16.0
        : isTablet
        ? 15.0
        : 14.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Food Log', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.offNamed(Routes.home),
        ),
      ),
      body: Center(
        child: SizedBox(
          width: contentMaxWidth,
          child: ListView(
            padding: EdgeInsets.fromLTRB(hPadding, 14, hPadding, 90),
            children: [
              AnimatedReveal(
                delay: const Duration(milliseconds: 60),
                child: SizedBox(
                  height: chipHeight,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _meals.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final selected = _selectedMeal == _meals[i];
                      return ChoiceChip(
                        selected: selected,
                        label: Text(
                          _meals[i],
                          style: TextStyle(fontSize: isDesktop ? 14 : 12),
                        ),
                        onSelected: (_) =>
                            setState(() => _selectedMeal = _meals[i]),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppColors.textPrimaryFor(context),
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const AnimatedReveal(
                delay: Duration(milliseconds: 100),
                child: Row(
                  children: [
                    Expanded(child: _MealTag(label: 'Burger')),
                    SizedBox(width: 8),
                    Expanded(child: _MealTag(label: 'Pizza')),
                    SizedBox(width: 8),
                    Expanded(child: _MealTag(label: 'Apple')),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AnimatedReveal(
                delay: const Duration(milliseconds: 150),
                child: Container(
                  padding: EdgeInsets.all(isDesktop ? 16 : 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search for a food...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: AppColors.surfaceMuted(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(44),
                        ),
                        onPressed: () {},
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan Barcode'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              AnimatedReveal(
                delay: const Duration(milliseconds: 210),
                child: Container(
                  padding: EdgeInsets.all(isDesktop ? 16 : 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Daily Summary',
                            style: TextStyle(
                              fontSize: isDesktop
                                  ? 28
                                  : isTablet
                                  ? 25
                                  : 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textTitleFor(context),
                            ),
                          ),
                          const Spacer(),
                          _miniIcon(Icons.add, Colors.blue, _showAddFoodDialog),
                          const SizedBox(width: 8),
                          _miniIcon(
                            Icons.restaurant_menu,
                            Colors.green,
                            _showAddRecipeDialog,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: summaryGridCount,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: summaryAspect,
                        children: [
                          _summary(
                            '$_totalCalories',
                            'Calories',
                            valueSize: summaryValueSize,
                            labelSize: summaryLabelSize,
                          ),
                          _summary(
                            '${_totalProtein}g',
                            'Protein',
                            valueSize: summaryValueSize,
                            labelSize: summaryLabelSize,
                          ),
                          _summary(
                            '${_totalCarbs}g',
                            'Carbs',
                            valueSize: summaryValueSize,
                            labelSize: summaryLabelSize,
                          ),
                          _summary(
                            '${_totalFat}g',
                            'Fat',
                            valueSize: summaryValueSize,
                            labelSize: summaryLabelSize,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._mealData.entries
                          .where((e) => e.value.isNotEmpty)
                          .map((e) => _mealSection(context, e.key, e.value)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _showAddFoodDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const HomeBottomNav(selected: 'Food Log'),
    );
  }

  Widget _field(TextEditingController c, String label, {int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _miniIcon(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _summary(
    String value,
    String label, {
    required double valueSize,
    required double labelSize,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted(context),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: valueSize),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: labelSize)),
        ],
      ),
    );
  }

  Widget _mealSection(
    BuildContext context,
    String title,
    List<_FoodItem> items,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textTitleFor(context),
            ),
          ),
          const SizedBox(height: 4),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      color: AppColors.textSecondaryFor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _kv('${item.calories}', 'Cal'),
                      _kv('${item.carbs}g', 'Carbs'),
                      _kv('${item.fat}g', 'Fat'),
                      _kv('${item.protein}g', 'Protein'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

class _MealTag extends StatelessWidget {
  final String label;
  const _MealTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE25C4E),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _FoodItem {
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  const _FoodItem({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}
