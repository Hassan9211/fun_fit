import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_api_service.dart';
import '../services/auth_session_storage.dart';
import '../widget/app_colors.dart';

class LanguagePreferencesScreen extends StatefulWidget {
  const LanguagePreferencesScreen({super.key});

  @override
  State<LanguagePreferencesScreen> createState() =>
      _LanguagePreferencesScreenState();
}

class _LanguagePreferencesScreenState extends State<LanguagePreferencesScreen> {
  static const String _languageKey = 'language_preference';
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

  String? _selectedLanguage;
  final AuthApiService _authApi = AuthApiService();

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_languageKey);
    if (!mounted) return;
    setState(() => _selectedLanguage = saved ?? 'English');
  }

  Future<void> _saveLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, value);
    final token = await AuthSessionStorage.readToken();
    if (token.isEmpty) return;
    await _authApi.updatePreferences(
      languageCode: value,
      bearerToken: token,
    );
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
                        child: Text(language),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedLanguage = value);
                  _saveLanguage(value);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
