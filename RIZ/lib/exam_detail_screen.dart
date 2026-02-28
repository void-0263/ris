import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'profile_service.dart';

class ExamDetailScreen extends StatefulWidget {
  final String categoryId;
  final String jobRoleId;
  final String examId;
  final Color categoryColor;

  const ExamDetailScreen({
    super.key,
    required this.categoryId,
    required this.jobRoleId,
    required this.examId,
    required this.categoryColor,
  });

  @override
  State<ExamDetailScreen> createState() => _ExamDetailScreenState();
}

class _ExamDetailScreenState extends State<ExamDetailScreen> {
  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    _profileService.startStudySession('ExamDetail_${widget.examId}');
    _profileService.trackResourceAccessed();
  }

  @override
  void dispose() {
    _profileService.endStudySession();
    super.dispose();
  }

  int? _daysLeft(String? dateStr) {
    if (dateStr == null) return null;
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
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('categories')
          .doc(widget.categoryId)
          .collection('jobRoles')
          .doc(widget.jobRoleId)
          .collection('exams')
          .doc(widget.examId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            body: Center(
                child: CircularProgressIndicator(color: widget.categoryColor)),
          );
        }
        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        return _buildScreen(context, data);
      },
    );
  }

  Widget _buildScreen(BuildContext context, Map<String, dynamic> data) {
    final examDate = data['examDate'] as String? ?? 'TBA';
    final days = _daysLeft(data['examDate'] as String?);
    final syllabus = (data['syllabus'] as List?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // ── AppBar ──
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: widget.categoryColor,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon:
                    const Icon(Icons.open_in_new_rounded, color: Colors.white),
                onPressed: () => _launchUrl(data['officialLink'] as String?),
                tooltip: 'Official Site',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.categoryColor,
                      widget.categoryColor.withValues(alpha: 0.8)
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(data['name'] as String? ?? '',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Ubuntu')),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _headerChip(Icons.calendar_today_rounded, examDate),
                            if (days != null) ...[
                              const SizedBox(width: 8),
                              _headerChip(
                                  Icons.timer_rounded, '$days days left',
                                  isUrgent: days < 30),
                            ],
                          ],
                        ),
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
                  // ── Countdown Banner ──
                  if (days != null) _buildCountdownBanner(days),
                  if (days != null) const SizedBox(height: 16),

                  // ── Key Info Grid ──
                  _buildKeyInfoGrid(data),
                  const SizedBox(height: 16),

                  // ── Exam Pattern ──
                  _buildSection(
                    icon: Icons.assignment_rounded,
                    title: 'Exam Pattern',
                    child: _buildPatternCard(
                        data['examPattern'] as String? ?? '-'),
                  ),
                  const SizedBox(height: 16),

                  // ── Syllabus ──
                  if (syllabus.isNotEmpty) ...[
                    _buildSection(
                      icon: Icons.menu_book_rounded,
                      title: 'Syllabus',
                      child: _buildSyllabus(syllabus),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Study Links ──
                  _buildSection(
                    icon: Icons.link_rounded,
                    title: 'Study Resources',
                    child: _buildStudyLinks(),
                  ),
                  const SizedBox(height: 16),

                  // ── Official Notification Button ──
                  _buildOfficialButton(data['officialLink'] as String?),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerChip(IconData icon, String label, {bool isUrgent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isUrgent
            ? Colors.red.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Ubuntu')),
        ],
      ),
    );
  }

  Widget _buildCountdownBanner(int days) {
    Color bannerColor;
    String message;
    IconData icon;

    if (days <= 30) {
      bannerColor = Colors.red;
      message =
          '⚡ Final stretch! Only $days days to go. Intensify your preparation!';
      icon = Icons.warning_rounded;
    } else if (days <= 90) {
      bannerColor = Colors.orange;
      message =
          '📚 $days days remaining. Stay consistent with your daily targets!';
      icon = Icons.timeline_rounded;
    } else {
      bannerColor = Colors.green;
      message = '✅ $days days to prepare. Build strong foundations now!';
      icon = Icons.check_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bannerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: bannerColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    fontSize: 13,
                    color: bannerColor,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Ubuntu',
                    height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyInfoGrid(Map<String, dynamic> data) {
    final items = [
      {
        'icon': Icons.calendar_today_rounded,
        'label': 'Exam Date',
        'value': data['examDate'] ?? 'TBA',
        'color': widget.categoryColor
      },
      {
        'icon': Icons.app_registration_rounded,
        'label': 'Registration',
        'value':
            '${data['registrationStart'] ?? 'TBA'} to ${data['registrationDeadline'] ?? 'TBA'}',
        'color': Colors.blue
      },
      {
        'icon': Icons.currency_rupee_rounded,
        'label': 'Application Fee',
        'value': data['applicationFee'] ?? '-',
        'color': Colors.green
      },
      {
        'icon': Icons.people_rounded,
        'label': 'Vacancies',
        'value': data['totalVacancies'] ?? '-',
        'color': Colors.purple
      },
      {
        'icon': Icons.computer_rounded,
        'label': 'Exam Mode',
        'value': data['examMode'] ?? '-',
        'color': Colors.teal
      },
    ];

    return Column(
      children: List.generate((items.length / 2).ceil(), (row) {
        final start = row * 2;
        final end = (start + 2).clamp(0, items.length);
        final rowItems = items.sublist(start, end);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              ...rowItems.asMap().entries.map((e) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          left: e.key > 0 ? 5 : 0,
                          right: e.key < rowItems.length - 1 ? 5 : 0),
                      child: _infoTile(
                        icon: e.value['icon'] as IconData,
                        label: e.value['label'] as String,
                        value: e.value['value'] as String,
                        color: e.value['color'] as Color,
                      ),
                    ),
                  )),
              if (rowItems.length < 2) const Expanded(child: SizedBox()),
            ],
          ),
        );
      }),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Ubuntu')),
            ],
          ),
          const SizedBox(height: 5),
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

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: widget.categoryColor, size: 18),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: widget.categoryColor,
                    fontFamily: 'Ubuntu')),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _buildPatternCard(String pattern) {
    // Split pattern into bullets at periods/commas
    final parts = pattern
        .split(RegExp(r'[.]'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: parts
            .map((part) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 5, right: 10),
                        decoration: BoxDecoration(
                            color: widget.categoryColor,
                            shape: BoxShape.circle),
                      ),
                      Expanded(
                        child: Text(part.trim(),
                            style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                                fontFamily: 'Ubuntu',
                                height: 1.5)),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildSyllabus(List<Map<String, dynamic>> syllabus) {
    return Column(
      children: syllabus.map((subject) {
        final topics = (subject['topics'] as List?)?.cast<String>() ?? [];
        return _SyllabusExpansion(
          subject: subject['subject'] as String? ?? '',
          topics: topics,
          color: widget.categoryColor,
        );
      }).toList(),
    );
  }

  Widget _buildStudyLinks() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('categories')
          .doc(widget.categoryId)
          .collection('jobRoles')
          .doc(widget.jobRoleId)
          .collection('exams')
          .doc(widget.examId)
          .collection('studyLinks')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Study links coming soon',
                style: TextStyle(fontFamily: 'Ubuntu', color: Colors.grey)),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _StudyLinkTile(
              data: data,
              color: widget.categoryColor,
              onTap: () {
                _profileService.trackResourceAccessed();
                _launchUrl(data['url'] as String?);
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildOfficialButton(String? url) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _launchUrl(url),
        icon: const Icon(Icons.open_in_new_rounded),
        label: const Text('View Official Notification',
            style: TextStyle(
                fontFamily: 'Ubuntu',
                fontWeight: FontWeight.w700,
                fontSize: 15)),
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.categoryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 4,
          shadowColor: widget.categoryColor.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  void _launchUrl(String? url) async {
    if (url == null) return;
    HapticFeedback.lightImpact();
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}

// ─────────────────────────────────────────────────────────────
// Expandable Syllabus Section
// ─────────────────────────────────────────────────────────────
class _SyllabusExpansion extends StatefulWidget {
  final String subject;
  final List<String> topics;
  final Color color;

  const _SyllabusExpansion({
    required this.subject,
    required this.topics,
    required this.color,
  });

  @override
  State<_SyllabusExpansion> createState() => _SyllabusExpansionState();
}

class _SyllabusExpansionState extends State<_SyllabusExpansion> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _expanded
                    ? widget.color.withValues(alpha: 0.06)
                    : Colors.transparent,
                borderRadius: _expanded
                    ? const BorderRadius.vertical(top: Radius.circular(12))
                    : BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.subject_rounded,
                        color: widget.color, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.subject,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: widget.color,
                            fontFamily: 'Ubuntu')),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${widget.topics.length} topics',
                        style: TextStyle(
                            fontSize: 10,
                            color: widget.color,
                            fontFamily: 'Ubuntu',
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: widget.color,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.topics
                    .map((topic) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: widget.color.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: widget.color.withValues(alpha: 0.2)),
                          ),
                          child: Text(topic,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: widget.color,
                                  fontFamily: 'Ubuntu')),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Study Link Tile
// ─────────────────────────────────────────────────────────────
class _StudyLinkTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color color;
  final VoidCallback onTap;

  const _StudyLinkTile({
    required this.data,
    required this.color,
    required this.onTap,
  });

  IconData _iconForType(String type) {
    switch (type) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'video':
        return Icons.play_circle_rounded;
      case 'practice':
        return Icons.quiz_rounded;
      case 'book':
        return Icons.menu_book_rounded;
      default:
        return Icons.article_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = data['type'] as String? ?? 'article';
    final free = data['free'] as bool? ?? true;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_iconForType(type), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['title'] as String? ?? '',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          fontFamily: 'Ubuntu')),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (free ? Colors.green : Colors.orange)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(free ? 'FREE' : 'PAID',
                            style: TextStyle(
                                fontSize: 9,
                                color: free ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Ubuntu')),
                      ),
                      const SizedBox(width: 6),
                      Text(type.toUpperCase(),
                          style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[400],
                              fontFamily: 'Ubuntu',
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}
