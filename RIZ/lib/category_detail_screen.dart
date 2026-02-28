import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'job_role_screen.dart';

class CategoryDetailScreen extends StatelessWidget {
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final Color categoryColor;

  const CategoryDetailScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: categoryColor,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [categoryColor, categoryColor.withValues(alpha: 0.75)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(categoryIcon, style: const TextStyle(fontSize: 36)),
                  const SizedBox(height: 8),
                  Text(categoryName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Ubuntu')),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('categories')
                        .doc(categoryId)
                        .snapshots(),
                    builder: (_, snap) {
                      final data = snap.data?.data() as Map<String, dynamic>?;
                      final fullName = data?['fullName'] ?? '';
                      return Text(fullName,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                              fontFamily: 'Ubuntu'));
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('categories')
          .doc(categoryId)
          .collection('jobRoles')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 400,
            child:
                Center(child: CircularProgressIndicator(color: categoryColor)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyState();
        }

        final docs = snapshot.data!.docs;

        // Group by classType
        final Map<String, List<QueryDocumentSnapshot>> grouped = {};
        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final classType = data['classType'] as String? ?? 'Other';
          grouped.putIfAbsent(classType, () => []).add(doc);
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats row
              _buildStatsRow(docs.length),
              const SizedBox(height: 24),
              // Job roles grouped
              ...grouped.entries.map((entry) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Class type header
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: categoryColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(entry.key,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: categoryColor,
                                fontFamily: 'Ubuntu',
                                letterSpacing: 0.5)),
                      ),
                      // Job role cards in this group
                      ...entry.value.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return _JobRoleCard(
                          docId: doc.id,
                          data: data,
                          categoryId: categoryId,
                          categoryName: categoryName,
                          categoryColor: categoryColor,
                        );
                      }),
                      const SizedBox(height: 8),
                    ],
                  )),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsRow(int jobRoleCount) {
    return Row(
      children: [
        _statChip(Icons.work_rounded, '$jobRoleCount Job Roles', categoryColor),
        const SizedBox(width: 10),
        _statChip(Icons.verified_rounded, 'Official Data', Colors.green),
      ],
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Ubuntu')),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty_rounded,
                size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Content Coming Soon',
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[500],
                    fontFamily: 'Ubuntu',
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
class _JobRoleCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String categoryId;
  final String categoryName;
  final Color categoryColor;

  const _JobRoleCard({
    required this.docId,
    required this.data,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    final hierarchy = (data['hierarchy'] as List?)?.cast<String>() ?? [];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JobRoleScreen(
            categoryId: categoryId,
            jobRoleId: docId,
            categoryColor: categoryColor,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.06),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: categoryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.work_outline_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['title'] as String? ?? '',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: categoryColor,
                                fontFamily: 'Ubuntu')),
                        Text(data['shortDescription'] as String? ?? '',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontFamily: 'Ubuntu')),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: categoryColor, size: 24),
                ],
              ),
            ),

            // Salary
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Icon(Icons.currency_rupee_rounded,
                      size: 14, color: Colors.green[700]),
                  const SizedBox(width: 4),
                  Text(data['salary'] as String? ?? '',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Ubuntu')),
                ],
              ),
            ),

            // Eligibility
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.school_rounded, size: 14, color: Colors.blue[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(data['eligibility'] as String? ?? '',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontFamily: 'Ubuntu'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),

            // Top hierarchy posts preview
            if (hierarchy.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...hierarchy.take(4).map((post) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: categoryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(post,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: categoryColor,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Ubuntu')),
                        )),
                    if (hierarchy.length > 4)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('+\${hierarchy.length - 4} more',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                                fontFamily: 'Ubuntu')),
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
