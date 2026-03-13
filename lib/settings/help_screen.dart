import 'package:flutter/material.dart';

import '../services/auth_api_service.dart';
import '../widget/app_colors.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AuthApiService _authApi = AuthApiService();
  List<_HelpItemData> _items = _defaultHelpItems;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadHelp();
  }

  Future<void> _loadHelp() async {
    final result = await _authApi.fetchHelpFaqs();
    if (!mounted || !result.success) return;
    final items = _parseHelpItems(result.data);
    if (items.isEmpty) return;
    setState(() => _items = items);
  }

  List<_HelpItemData> _parseHelpItems(Map<String, dynamic>? response) {
    if (response == null) return const <_HelpItemData>[];
    final data = response['items'] ?? response['data'] ?? response['results'];
    final list = data is List ? data : (data == null ? [] : [data]);
    return list
        .map<_HelpItemData?>((item) {
          if (item is! Map) return null;
          final map = item.map((key, value) => MapEntry(key.toString(), value));
          final question = (map['question'] ?? map['title'] ?? '').toString();
          final answer = (map['answer'] ?? map['content'] ?? '').toString();
          if (question.trim().isEmpty || answer.trim().isEmpty) return null;
          return _HelpItemData(question: question.trim(), answer: answer.trim());
        })
        .whereType<_HelpItemData>()
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          'Help',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted(context),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'search for help',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: const Icon(Icons.tune),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView(
                  children: _items
                      .expand((item) => <Widget>[
                            _HelpItem(
                              question: item.question,
                              answer: item.answer,
                            ),
                            const SizedBox(height: 10),
                          ])
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpItemData {
  final String question;
  final String answer;

  const _HelpItemData({required this.question, required this.answer});
}

const List<_HelpItemData> _defaultHelpItems = <_HelpItemData>[
  _HelpItemData(
    question: 'How do I manage my notifications?',
    answer:
        'Go to Settings, open Notification Settings, then customize your reminder and update preferences.',
  ),
  _HelpItemData(
    question: 'How do I start a guided of my yoga session?',
    answer:
        'Open Guides, choose a yoga routine, then tap Start Session to begin the guided workout.',
  ),
  _HelpItemData(
    question: 'How do I join a support group?',
    answer:
        'Open Community from Home and choose a support group that matches your goal.',
  ),
  _HelpItemData(
    question: 'How do I manage my Fitness?',
    answer:
        'Use Goal, Fitness Level, and daily tracking in Home to monitor and adjust your plan.',
  ),
];

class _HelpItem extends StatelessWidget {
  final String question;
  final String answer;

  const _HelpItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        title: Text(
          question,
          style: TextStyle(
            color: AppColors.textTitleFor(context),
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        iconColor: AppColors.textPrimaryFor(context),
        collapsedIconColor: AppColors.textPrimaryFor(context),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
        children: [
          Text(
            answer,
            style: TextStyle(
              color: AppColors.textSecondaryFor(context),
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
