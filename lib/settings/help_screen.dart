import 'package:flutter/material.dart';

import '../widget/app_colors.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                  children: const [
                    _HelpItem(
                      question: 'How do I manage my notifications?',
                      answer:
                          'Go to Settings, open Notification Settings, then customize your reminder and update preferences.',
                    ),
                    SizedBox(height: 10),
                    _HelpItem(
                      question: 'How do I start a guided of my yoga session?',
                      answer:
                          'Open Guides, choose a yoga routine, then tap Start Session to begin the guided workout.',
                    ),
                    SizedBox(height: 10),
                    _HelpItem(
                      question: 'How do I join a support group?',
                      answer:
                          'Open Community from Home and choose a support group that matches your goal.',
                    ),
                    SizedBox(height: 10),
                    _HelpItem(
                      question: 'How do I manage my Fitness?',
                      answer:
                          'Use Goal, Fitness Level, and daily tracking in Home to monitor and adjust your plan.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
