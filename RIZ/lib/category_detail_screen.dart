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

  // ── FIX 1: expandedHeight increased to 200 so title + subtitle never get clipped ──
  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      collapsedHeight: 64,
      pinned: true,
      backgroundColor: categoryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                categoryColor,
                categoryColor.withValues(alpha: 0.82),
              ],
            ),
          ),
          // Use LayoutBuilder so content never overflows the header
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    categoryIcon,
                    style: const TextStyle(fontSize: 38),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    categoryName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Ubuntu',
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Pull fullName from Firestore
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('categories')
                        .doc(categoryId)
                        .snapshots(),
                    builder: (_, snap) {
                      final data = snap.data?.data() as Map<String, dynamic>?;
                      final fullName = data?['fullName'] as String? ?? '';
                      return Text(
                        fullName,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 13,
                          fontFamily: 'Ubuntu',
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      );
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

        // Group by classType, preserving insertion order
        final Map<String, List<QueryDocumentSnapshot>> grouped =
            <String, List<QueryDocumentSnapshot>>{};
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
              _buildStatsRow(docs.length),
              const SizedBox(height: 24),
              ...grouped.entries.map(
                (entry) => _GroupSection(
                  classType: entry.key,
                  docs: entry.value,
                  categoryId: categoryId,
                  categoryName: categoryName,
                  categoryColor: categoryColor,
                ),
              ),
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
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w700,
              fontFamily: 'Ubuntu',
            ),
          ),
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
            Text(
              'Content Coming Soon',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
                fontFamily: 'Ubuntu',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Group section widget (Class I & II header + cards under it) ──
class _GroupSection extends StatelessWidget {
  final String classType;
  final List<QueryDocumentSnapshot> docs;
  final String categoryId;
  final String categoryName;
  final Color categoryColor;

  const _GroupSection({
    required this.classType,
    required this.docs,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Class type header badge
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: categoryColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: categoryColor.withValues(alpha: 0.30)),
          ),
          child: Text(
            classType,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: categoryColor,
              fontFamily: 'Ubuntu',
              letterSpacing: 0.4,
            ),
          ),
        ),
        // Cards
        ...docs.map((doc) {
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
    // ── FIX 2: extraCount computed as plain int — no string interpolation issue ──
    final extraCount = hierarchy.length - 4;

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
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card header ──
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
                        Text(
                          data['title'] as String? ?? '',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: categoryColor,
                            fontFamily: 'Ubuntu',
                          ),
                        ),
                        Text(
                          data['shortDescription'] as String? ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: 'Ubuntu',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: categoryColor, size: 24),
                ],
              ),
            ),

            // ── Salary ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Icon(Icons.currency_rupee_rounded,
                      size: 14, color: Colors.green[700]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      data['salary'] as String? ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Ubuntu',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Eligibility ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.school_rounded, size: 14, color: Colors.blue[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      data['eligibility'] as String? ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontFamily: 'Ubuntu',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // ── Hierarchy chips preview ──
            if (hierarchy.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    // Show first 4 posts as chips
                    ...hierarchy.take(4).map(
                          (post) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              post,
                              style: TextStyle(
                                fontSize: 10,
                                color: categoryColor,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Ubuntu',
                              ),
                            ),
                          ),
                        ),
                    // ── FIX 2: +N more chip — correct Dart interpolation
                    if (extraCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          '+$extraCount more',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontFamily: 'Ubuntu',
                            fontWeight: FontWeight.w600,
                          ),
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
