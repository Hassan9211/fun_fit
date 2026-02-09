import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FoodLoggingScreen extends StatelessWidget {
  const FoodLoggingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    String? selectedMeal;
    if (args is Map && args['meal'] is String) {
      selectedMeal = args['meal'] as String;
    }
    return _FoodLoggingScaffold(selectedMeal: selectedMeal);
  }
}

class AddMealScreen extends StatelessWidget {
  const AddMealScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AddMealScaffold();
  }
}

class _FoodLoggingScaffold extends StatelessWidget {
  final String? selectedMeal;

  const _FoodLoggingScaffold({this.selectedMeal});

  int _selectedIndex() {
    switch (selectedMeal) {
      case 'Lunch':
        return 1;
      case 'Dinner':
        return 2;
      case 'Snacks':
        return 3;
      case 'Water':
        return 4;
      case 'Breakfast':
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FB),
      body: SafeArea(
        child: Column(
          children: [
            _BlueHeader(title: 'Food Logging', showBack: true),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  _SegmentedTabs(
                    items: ['Breakfast', 'Lunch', 'Dinner', 'Snacks', 'Water'],
                    selectedIndex: _selectedIndex(),
                  ),
                  const SizedBox(height: 18),
                  if (selectedMeal != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Selected: $selectedMeal',
                        style: const TextStyle(
                          color: Color(0xFF1D3DBB),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const Text(
                    'Previous Meal:',
                    style: TextStyle(
                      color: Color(0xFF5E6B86),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: const [
                      Expanded(
                        child: _ChipPill(
                          label: 'Burger',
                          color: Color(0xFFE46A55),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _ChipPill(
                          label: 'Pizza',
                          color: Color(0xFFE46A55),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _ChipPill(
                          label: 'Apple',
                          color: Color(0xFFE46A55),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        _InputField(
                          hint: 'Search for a food...',
                          prefixIcon: Icons.search,
                        ),
                        const SizedBox(height: 10),
                        _InputField(
                          hint: 'Meal name',
                          initialValue: selectedMeal,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: const [
                            Expanded(child: _InputField(hint: 'Portion sizes')),
                            SizedBox(width: 10),
                            _DropdownPill(initialValue: 'Kilograms (kg)'),
                          ],
                        ),
                        const SizedBox(height: 25),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1D3DBB),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {},
                            icon: const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Add Photo',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        const _MacroRow(),
                        const SizedBox(height: 25),
                        const _GoalsBlock(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMealScaffold extends StatelessWidget {
  const _AddMealScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FB),
      body: SafeArea(
        child: Column(
          children: [
            _BlueHeader(title: 'Add Meal', showBack: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  Text(
                    'Meal Planner',
                    style: TextStyle(
                      color: Color(0xFF5E6B86),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 14),
                  _PlannerTile(
                    title: 'Breakfast',
                    onTap: () => Get.toNamed(
                      '/food-logging',
                      arguments: {'meal': 'Breakfast'},
                    ),
                  ),
                  _PlannerTile(
                    title: 'Lunch',
                    onTap: () => Get.toNamed(
                      '/food-logging',
                      arguments: {'meal': 'Lunch'},
                    ),
                  ),
                  _PlannerTile(
                    title: 'Dinner',
                    onTap: () => Get.toNamed(
                      '/food-logging',
                      arguments: {'meal': 'Dinner'},
                    ),
                  ),
                  _PlannerTile(
                    title: 'Snacks',
                    onTap: () => Get.toNamed(
                      '/food-logging',
                      arguments: {'meal': 'Snacks'},
                    ),
                  ),
                  _PlannerTile(
                    title: 'Water',
                    onTap: () => Get.toNamed(
                      '/food-logging',
                      arguments: {'meal': 'Water'},
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlueHeader extends StatelessWidget {
  final String title;
  final bool showBack;

  const _BlueHeader({required this.title, this.showBack = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1D3DBB),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Row(
        children: [
          if (showBack)
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_back, size: 18),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 34),
        ],
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  final List<String> items;
  final int selectedIndex;

  const _SegmentedTabs({required this.items, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF2A4BD0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final selected = index == selectedIndex;
          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                items[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? const Color(0xFF1D3DBB) : Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ChipPill extends StatelessWidget {
  final String label;
  final Color color;

  const _ChipPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String hint;
  final IconData? prefixIcon;
  final String? initialValue;

  const _InputField({required this.hint, this.prefixIcon, this.initialValue});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18) : null,
        filled: true,
        fillColor: const Color(0xFFF6F7FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}

class _DropdownPill extends StatefulWidget {
  final String initialValue;

  const _DropdownPill({required this.initialValue});

  @override
  State<_DropdownPill> createState() => _DropdownPillState();
}

class _DropdownPillState extends State<_DropdownPill> {
  static const _items = [
    'Grams (g)',
    'Kilograms (kg)',
    'Ounces (oz)',
    'Pounds (lb)',
  ];

  late String _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _value,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16),
          items: _items
              .map(
                (label) => DropdownMenuItem(
                  value: label,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _value = value);
          },
        ),
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _MacroDial(),
        SizedBox(width: 16),
        Expanded(
          child: _MacroStat(label: 'Carbs', value: '0g', percent: '0%'),
        ),
        Expanded(
          child: _MacroStat(label: 'Fat', value: '0g', percent: '0%'),
        ),
        Expanded(
          child: _MacroStat(label: 'Protein', value: '0g', percent: '0%'),
        ),
      ],
    );
  }
}

class _MacroDial extends StatelessWidget {
  const _MacroDial();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF1D3DBB), width: 2),
      ),
      child: const Center(
        child: Text(
          'Cal',
          style: TextStyle(
            color: Color(0xFF1D3DBB),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MacroStat extends StatelessWidget {
  final String label;
  final String value;
  final String percent;

  const _MacroStat({
    required this.label,
    required this.value,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          percent,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF1D3DBB),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
        ),
      ],
    );
  }
}

class _GoalsBlock extends StatelessWidget {
  const _GoalsBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Percent of Your Daily Goals',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Calories', style: TextStyle(fontWeight: FontWeight.w600)),
            Text('Carbs', style: TextStyle(fontWeight: FontWeight.w600)),
            Text('Fat', style: TextStyle(fontWeight: FontWeight.w600)),
            Text('Protein', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        Container(height: 2, color: const Color(0xFFE5E7EB)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [Text('0%'), Text('1,970'), Text('--'), Text('--')],
        ),
      ],
    );
  }
}

class _PlannerTile extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const _PlannerTile({required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xFFE4F8E7),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1D3DBB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
