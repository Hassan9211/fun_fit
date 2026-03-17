import 'package:flutter/material.dart';

import '../services/auth_api_service.dart';
import '../services/auth_session_storage.dart';
import '../widget/app_colors.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isPremiumTab = false;
  bool _isSubmitting = false;
  int _selectedDurationDays = 30;
  final ScrollController _scrollController = ScrollController();
  final AuthApiService _authApi = AuthApiService();

  static const List<String> _basicFeatures = <String>[
    '3 beginner-level challenges per day',
    '1 daily workout video',
    'Manual meal logging',
    'General meal guides',
    'Basic trial access up to Gold III',
    'Global leaderboard view',
    '3 weekly video uploads (No HD)',
    '1 free tutorial + 1 free workout video/week',
  ];

  static const List<String> _premiumFeatures = <String>[
    'Unlimited challenges based on fitness level',
    'Access to 100+ curated workout videos',
    'Add personalized challenges',
    'Personalized meal plans',
    'Advanced meal logging + barcode scan',
    'Micronutrient tracking',
    'Unlimited HD video uploads',
    'Elite difficulty challenges',
    'Personal leaderboard rank, badges, highlights',
    'Time extension vault (bank 60 days)',
    '100% ad-free',
    'Offline mode support',
    'Challenge chat rooms + expert Q&A',
    'Motivational alerts & reminders',
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openPremiumSection() {
    if (!_isPremiumTab) {
      setState(() => _isPremiumTab = true);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _showResultPopup(String title, String message) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<int?> _pickDuration() async {
    const options = <int, String>{
      30: 'Monthly',
      90: 'Quarterly',
      365: 'Yearly',
    };

    return showDialog<int>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (dialogContext) {
        int selected = _selectedDurationDays;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Choose duration'),
              content: DropdownButtonFormField<int>(
                initialValue: selected,
                items: options.entries
                    .map(
                      (entry) => DropdownMenuItem<int>(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => selected = value);
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(null),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(selected),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _onContinuePressed(bool isPremium) async {
    if (_isSubmitting) return;
    if (isPremium) {
      _openPremiumSection();
    }

    int durationDays = _selectedDurationDays;
    if (isPremium) {
      final picked = await _pickDuration();
      if (picked == null) return;
      durationDays = picked;
      if (mounted) {
        setState(() => _selectedDurationDays = picked);
      }
    }

    setState(() => _isSubmitting = true);
    try {
      final token = await AuthSessionStorage.readToken();
      if (token.isEmpty) {
        await _showResultPopup(
          'Login required',
          'Please sign in to continue.',
        );
        return;
      }

      final now = DateTime.now();
      final startDate = _formatDate(now);
      final endDate = _formatDate(now.add(Duration(days: durationDays)));
      final date = startDate;
      final duration = durationDays.toString();

      final result = isPremium
          ? await _authApi.createSubscription(
              data: <String, dynamic>{
                'plan': 'premium',
                'status': 'active',
                'duration': duration,
                'start_date': startDate,
                'end_date': endDate,
                'date': date,
              },
              bearerToken: token,
            )
          : await _authApi.updateSubscription(
              data: <String, dynamic>{
                'plan': 'basic',
                'status': 'active',
                'duration': duration,
                'start_date': startDate,
                'end_date': endDate,
                'date': date,
              },
              bearerToken: token,
            );

      await _showResultPopup(
        result.success ? 'Subscribed' : 'Subscription failed',
        result.message,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = _isPremiumTab;
    final features = isPremium ? _premiumFeatures : _basicFeatures;
    final title = isPremium ? 'Premium Plan' : 'Basic Plan (Free)';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Subscription',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _TabButton(
                            label: 'Basic',
                            active: !isPremium,
                            onTap: () => setState(() => _isPremiumTab = false),
                          ),
                        ),
                        Expanded(
                          child: _TabButton(
                            label: 'Premium',
                            active: isPremium,
                            onTap: () => setState(() => _isPremiumTab = true),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      controller: _scrollController,
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted(context),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  color: AppColors.textTitleFor(context),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ...features.map((feature) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    '- $feature',
                                    style: TextStyle(
                                      color: AppColors.textPrimaryFor(context),
                                      fontSize: 13,
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting
                                      ? null
                                      : () => _onContinuePressed(isPremium),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : const Text(
                                          'Continue',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isPremium) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted(context),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Column(
                              children: [
                                _PriceCard(
                                  title: 'Monthly',
                                  price: '\$9.99/month',
                                  subtitle: 'All features, no ads',
                                ),
                                SizedBox(height: 10),
                                _PriceCard(
                                  title: 'Quarterly',
                                  price: '\$24.99 every 3 months',
                                  subtitle: 'Save 15%',
                                ),
                                SizedBox(height: 10),
                                _PriceCard(
                                  title: 'Yearly',
                                  price: '\$89.99/year',
                                  subtitle: 'Save 25% + 2 bonus months',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.textPrimaryFor(context),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final String title;
  final String price;
  final String subtitle;

  const _PriceCard({
    required this.title,
    required this.price,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.cFFDDE6FF,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            price,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 19,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.cFFDDE6FF, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
