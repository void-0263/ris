import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'exam_detail_screen.dart';

class JobRoleScreen extends StatelessWidget {
  final String categoryId;
  final String jobRoleId;
  final Color categoryColor;

  const JobRoleScreen({
    super.key,
    required this.categoryId,
    required this.jobRoleId,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('categories')
          .doc(categoryId)
          .collection('jobRoles')
          .doc(jobRoleId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            body:
                Center(child: CircularProgressIndicator(color: categoryColor)),
          );
        }
        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        return _buildScreen(context, data);
      },
    );
  }

  Widget _buildScreen(BuildContext context, Map<String, dynamic> data) {
    final hierarchy = (data['hierarchy'] as List?)?.cast<String>() ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: categoryColor,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: categoryColor,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(data['title'] as String? ?? '',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Ubuntu')),
                        Text(data['classType'] as String? ?? '',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontFamily: 'Ubuntu')),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description card
                  _buildInfoCard(
                    icon: Icons.info_outline_rounded,
                    title: 'About This Role',
                    color: categoryColor,
                    child: Text(data['description'] as String? ?? '',
                        style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            fontFamily: 'Ubuntu',
                            height: 1.6)),
                  ),
                  const SizedBox(height: 16),

                  // Eligibility + Salary row
                  Row(
                    children: [
                      Expanded(
                        child: _buildSmallInfoCard(
                          icon: Icons.school_rounded,
                          title: 'Eligibility',
                          value: data['eligibility'] as String? ?? '-',
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSmallInfoCard(
                          icon: Icons.currency_rupee_rounded,
                          title: 'Salary',
                          value: data['salary'] as String? ?? '-',
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Hierarchy
                  if (hierarchy.isNotEmpty) ...[
                    _buildInfoCard(
                      icon: Icons.account_tree_rounded,
                      title: 'Career Hierarchy (Lowest → Highest)',
                      color: categoryColor,
                      child: Column(
                        children: List.generate(hierarchy.length, (i) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: i == hierarchy.length - 1
                                            ? categoryColor
                                            : categoryColor.withValues(
                                                alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text('${i + 1}',
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: i == hierarchy.length - 1
                                                    ? Colors.white
                                                    : categoryColor,
                                                fontFamily: 'Ubuntu')),
                                      ),
                                    ),
                                    if (i < hierarchy.length - 1)
                                      Container(
                                          width: 2,
                                          height: 16,
                                          color: categoryColor.withValues(
                                              alpha: 0.2)),
                                  ],
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Text(hierarchy[i],
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight:
                                                i == hierarchy.length - 1
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                            color: i == hierarchy.length - 1
                                                ? categoryColor
                                                : Colors.black87,
                                            fontFamily: 'Ubuntu')),
                                  ),
                                ),
                                if (i == hierarchy.length - 1)
                                  Icon(Icons.star_rounded,
                                      color: categoryColor, size: 16),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Exams section
                  Row(
                    children: [
                      Icon(Icons.assignment_rounded,
                          color: categoryColor, size: 20),
                      const SizedBox(width: 8),
                      Text('Exams for this Role',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: categoryColor,
                              fontFamily: 'Ubuntu')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildExamsList(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('categories')
          .doc(categoryId)
          .collection('jobRoles')
          .doc(jobRoleId)
          .collection('exams')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: categoryColor));
        }
        if (snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text('No exams found',
                  style: TextStyle(fontFamily: 'Ubuntu')));
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _ExamCard(
              examId: doc.id,
              data: data,
              categoryId: categoryId,
              jobRoleId: jobRoleId,
              categoryColor: categoryColor,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Container(
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
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: color,
                        fontFamily: 'Ubuntu')),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildSmallInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(title,
                  style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Ubuntu')),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  fontFamily: 'Ubuntu',
                  height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
class _ExamCard extends StatelessWidget {
  final String examId;
  final Map<String, dynamic> data;
  final String categoryId;
  final String jobRoleId;
  final Color categoryColor;

  const _ExamCard({
    required this.examId,
    required this.data,
    required this.categoryId,
    required this.jobRoleId,
    required this.categoryColor,
  });

  int? _daysLeft() {
    final dateStr = data['examDate'] as String? ?? '';
    // try parsing first word as date
    try {
      final d = DateTime.parse(dateStr.split(' ')[0].split('/')[0]);
      final diff = d.difference(DateTime.now()).inDays;
      return diff >= 0 ? diff : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _daysLeft();
    final examDate = data['examDate'] as String? ?? 'TBA';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExamDetailScreen(
            categoryId: categoryId,
            jobRoleId: jobRoleId,
            examId: examId,
            categoryColor: categoryColor,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: days != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('$days',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: categoryColor,
                                  fontFamily: 'Ubuntu')),
                          Text('days',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: categoryColor,
                                  fontFamily: 'Ubuntu')),
                        ],
                      )
                    : Icon(Icons.assignment_rounded,
                        color: categoryColor, size: 24),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['name'] as String? ?? '',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          fontFamily: 'Ubuntu')),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(examDate,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                                fontFamily: 'Ubuntu'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(data['examPattern'] as String? ?? '',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[400],
                          fontFamily: 'Ubuntu'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: categoryColor, size: 16),
          ],
        ),
      ),
    );
  }
}
