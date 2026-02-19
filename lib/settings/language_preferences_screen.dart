import 'package:flutter/material.dart';

import '../widget/app_colors.dart';

class LanguagePreferencesScreen extends StatefulWidget {
  const LanguagePreferencesScreen({super.key});

  @override
  State<LanguagePreferencesScreen> createState() =>
      _LanguagePreferencesScreenState();
}

class _LanguagePreferencesScreenState extends State<LanguagePreferencesScreen> {
  static const List<String> _languages = <String>[
    'Arabic',
    'Bengali',
    'English',
    'French',
    'German',
    'Hindi',
    'Italian',
    'Japanese',
    'Javanese',
    'Korean',
    'Marathi',
    'Portuguese',
    'Russian',
    'Spanish',
    'Swahili',
    'Tamil',
    'Telugu',
    'Turkish',
    'Urdu',
  ];

  static const Map<String, String> _flags = <String, String>{
    'Arabic': '🇸🇦',
    'Bengali': '🇧🇩',
    'English': '🇬🇧',
    'French': '🇫🇷',
    'German': '🇩🇪',
    'Hindi': '🇮🇳',
    'Italian': '🇮🇹',
    'Japanese': '🇯🇵',
    'Javanese': '🇮🇩',
    'Korean': '🇰🇷',
    'Marathi': '🇮🇳',
    'Portuguese': '🇵🇹',
    'Russian': '🇷🇺',
    'Spanish': '🇪🇸',
    'Swahili': '🇰🇪',
    'Tamil': '🇮🇳',
    'Telugu': '🇮🇳',
    'Turkish': '🇹🇷',
    'Urdu': '🇵🇰',
  };

  String? _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = 'English';
  }

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'Language / Dropdown',
          style: TextStyle(color: onPrimary, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedLanguage,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down),
                decoration: InputDecoration(
                  labelText: 'Select Language',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: _languages
                    .map(
                      (language) => DropdownMenuItem<String>(
                        value: language,
                        child: Text('${_flags[language] ?? ''} $language'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedLanguage = value);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
