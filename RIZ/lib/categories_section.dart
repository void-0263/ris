import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'category_detail_screen.dart';

class CategoriesSection extends StatelessWidget {
  const CategoriesSection({super.key});

  // Fallback colors in case Firestore color is missing
  Color _parseColor(String? hex) {
    if (hex == null) return Colors.blueGrey;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 160,
            child: Center(
                child: CircularProgressIndicator(color: Color(0xFF2196F3))),
          );
        }

        // Fallback static list if Firestore not seeded yet
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildStaticCategories(context);
        }

        final docs = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final color = _parseColor(data['color'] as String?);
                  return _CategoryCard(
                    categoryId: docs[i].id,
                    name: data['name'] as String? ?? '',
                    icon: data['icon'] as String? ?? '📋',
                    color: color,
                    totalExams: data['totalExams'] as int? ?? 0,
                    totalJobRoles: data['totalJobRoles'] as int? ?? 0,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // Shown before Firestore is seeded
  Widget _buildStaticCategories(BuildContext context) {
    final categories = [
      {'id': 'tnpsc', 'name': 'TNPSC', 'icon': '🏛️', 'color': '#8B7355'},
      {'id': 'upsc', 'name': 'UPSC', 'icon': '🇮🇳', 'color': '#1565C0'},
      {'id': 'ssc', 'name': 'SSC', 'icon': '📝', 'color': '#6A1B9A'},
      {'id': 'banking', 'name': 'Banking', 'icon': '🏦', 'color': '#1B5E20'},
      {'id': 'railways', 'name': 'Railways', 'icon': '🚂', 'color': '#00695C'},
      {'id': 'defence', 'name': 'Defence', 'icon': '⚔️', 'color': '#B71C1C'},
    ];

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final cat = categories[i];
          return _CategoryCard(
            categoryId: cat['id']!,
            name: cat['name']!,
            icon: cat['icon']!,
            color: Color(int.parse(cat['color']!.replaceFirst('#', '0xFF'))),
            totalExams: 0,
            totalJobRoles: 0,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final String categoryId;
  final String name;
  final String icon;
  final Color color;
  final int totalExams;
  final int totalJobRoles;

  const _CategoryCard({
    required this.categoryId,
    required this.name,
    required this.icon,
    required this.color,
    required this.totalExams,
    required this.totalJobRoles,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CategoryDetailScreen(
            categoryId: categoryId,
            categoryName: name,
            categoryIcon: icon,
            categoryColor: color,
          ),
        ),
      ),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withValues(alpha: 0.8)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(icon, style: const TextStyle(fontSize: 32)),
              const Spacer(),
              Text(name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Ubuntu')),
              const SizedBox(height: 4),
              Text(
                totalJobRoles > 0
                    ? '$totalJobRoles roles · $totalExams exams'
                    : 'Tap to explore',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontFamily: 'Ubuntu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
