import 'package:flutter/material.dart';

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FB),
      body: SafeArea(
        child: Column(
          children: [
            const _BlueHeader(title: 'Challenges', showBack: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Choose Random Challenge',
                          style: TextStyle(
                            color: Color(0xFF5E6B86),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              Image.asset(
                                'assets/images/yoga.jpg',
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              Positioned.fill(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Color(0x990F172A),
                                        Color(0x000F172A),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 12,
                                right: 12,
                                bottom: 12,
                                child: SizedBox(
                                  height: 36,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1D3DBB),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {},
                                    child: const Text(
                                      'Select Random Challenge',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: const [
                      Expanded(
                        child: Text(
                          'Workout Category',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                      Text(
                        'View all',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8A94A6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 130,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: const [
                        _CategoryCard(
                          title: 'Yoga',
                          imagePath: 'assets/images/yoga.jpg',
                        ),
                        _CategoryCard(
                          title: 'Pilates',
                          imagePath: 'assets/images/pilates.jpg',
                        ),
                        _CategoryCard(
                          title: 'Calisthenics',
                          imagePath: 'assets/images/Calisthenics.jpg',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Current Challenges',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const _ChallengeTile(
                    title: 'Push Up',
                    subtitle: '100 Push up a day',
                    time: '5:00 min',
                    progress: 0.45,
                    imagePath: 'assets/images/pushup.jpg',
                  ),
                  const _ChallengeTile(
                    title: 'Sit Up',
                    subtitle: '20 Sit up a day',
                    time: '4:30 min',
                    progress: 0.70,
                    imagePath: 'assets/images/situp.jpg',
                  ),
                  const _ChallengeTile(
                    title: 'Knee Push Up',
                    subtitle: '20 Sit up a day',
                    time: '3:00 min',
                    progress: 0.35,
                    imagePath: 'assets/images/knee pushup.jpg',
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

class _CategoryCard extends StatelessWidget {
  final String title;
  final String imagePath;

  const _CategoryCard({required this.title, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [Color(0xAA0F172A), Color(0x001D3DBB)],
          ),
        ),
        child: Center(
          child: Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChallengeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final double progress;
  final String imagePath;

  const _ChallengeTile({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.progress,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              imagePath,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF1D3DBB)),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              const Icon(Icons.sync, size: 16, color: Color(0xFF6B7280)),
              const SizedBox(height: 8),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
