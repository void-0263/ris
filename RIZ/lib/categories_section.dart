// File: lib/categories_section.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Interactive Category Section Widget
/// Shows exam categories with real-time data
class CategoriesSection extends StatefulWidget {
  const CategoriesSection({super.key});

  @override
  State<CategoriesSection> createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends State<CategoriesSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get categories from backend
    final categories = CategoryBackend.getAllCategories();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      color: Colors.white,
      child: Column(
        children: [
          // Section Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Choose Your Category",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1976D2),
                fontFamily: 'Ubuntu',
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Categories Grid/List
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _CategoryCard(category: category, index: index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual Category Card
class _CategoryCard extends StatefulWidget {
  final CategoryData category;
  final int index;

  const _CategoryCard({required this.category, required this.index});

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    // Staggered animation
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onTapDown: (_) {
            setState(() => _isPressed = true);
            HapticFeedback.lightImpact();
          },
          onTapUp: (_) {
            setState(() => _isPressed = false);
            _navigateToCategoryDetail();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Container(
              width: 160,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(widget.category.color),
                    Color(widget.category.color).withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(widget.category.color).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon
                  Text(
                    widget.category.icon,
                    style: const TextStyle(fontSize: 32),
                  ),

                  // Title and subtitle
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.category.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'Ubuntu',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.category.jobRoles.length} exams',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontFamily: 'Ubuntu',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToCategoryDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryDetailScreen(category: widget.category),
      ),
    );
  }
}

/// Category Detail Screen
class CategoryDetailScreen extends StatelessWidget {
  final CategoryData category;

  const CategoryDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(category.color),
              Color(category.color).withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    Text(category.icon, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Ubuntu',
                            ),
                          ),
                          Text(
                            category.fullName,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontFamily: 'Ubuntu',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: category.jobRoles.length,
                    itemBuilder: (context, index) {
                      final jobRole = category.jobRoles.values.toList()[index];
                      return _JobRoleCard(
                        jobRole: jobRole,
                        categoryColor: Color(category.color),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Job Role Card
class _JobRoleCard extends StatelessWidget {
  final JobRoleData jobRole;
  final Color categoryColor;

  const _JobRoleCard({required this.jobRole, required this.categoryColor});

  @override
  Widget build(BuildContext context) {
    // Get next upcoming date
    final nextDate = jobRole.upcomingDates.isNotEmpty
        ? jobRole.upcomingDates.first
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Navigate to job role detail
            HapticFeedback.lightImpact();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.work_outline,
                        color: categoryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            jobRole.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                              fontFamily: 'Ubuntu',
                            ),
                          ),
                          Text(
                            jobRole.fullName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontFamily: 'Ubuntu',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ],
                ),

                if (nextDate != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: categoryColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: categoryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nextDate.event,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: categoryColor,
                                  fontFamily: 'Ubuntu',
                                ),
                              ),
                              Text(
                                _formatDate(nextDate.date),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontFamily: 'Ubuntu',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(nextDate.status),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            nextDate.status,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFamily: 'Ubuntu',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Exam count
                if (jobRole.exams.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${jobRole.exams.length} exam stages',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'Ubuntu',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.link, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        '${jobRole.studyLinks.length} resources',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'Ubuntu',
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.grey;
      case 'open':
        return Colors.green;
      case 'confirmed':
        return Colors.blue;
      case 'expected':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

// ============================================================================
// SIMPLIFIED BACKEND (Place this in a separate file: lib/category_backend.dart)
// ============================================================================

class CategoryBackend {
  static List<CategoryData> getAllCategories() {
    return [
      CategoryData(
        name: 'TNPSC',
        fullName: 'Tamil Nadu Public Service Commission',
        color: 0xFFBDB76B,
        icon: '🏛️',
        jobRoles: {
          'Group 1': JobRoleData(
            name: 'Group 1',
            fullName: 'Combined Civil Services Examination - Group 1',
            exams: [],
            upcomingDates: [
              ExamDate(
                event: 'Preliminary Examination',
                date: DateTime(2026, 9, 6),
                status: 'Confirmed',
              ),
            ],
            studyLinks: [],
          ),
        },
      ),
      CategoryData(
        name: 'UPSC',
        fullName: 'Union Public Service Commission',
        color: 0xFF1976D2,
        icon: '🇮🇳',
        jobRoles: {
          'Civil Services': JobRoleData(
            name: 'Civil Services',
            fullName: 'IAS/IPS/IFS Examination',
            exams: [],
            upcomingDates: [
              ExamDate(
                event: 'Preliminary Examination',
                date: DateTime(2026, 5, 24),
                status: 'Confirmed',
              ),
            ],
            studyLinks: [],
          ),
        },
      ),
      CategoryData(
        name: 'SSC',
        fullName: 'Staff Selection Commission',
        color: 0xFF7B1FA2,
        icon: '📝',
        jobRoles: {
          'CGL': JobRoleData(
            name: 'CGL',
            fullName: 'Combined Graduate Level',
            exams: [],
            upcomingDates: [],
            studyLinks: [],
          ),
        },
      ),
      CategoryData(
        name: 'Banking',
        fullName: 'Banking Sector Exams',
        color: 0xFFE65100,
        icon: '🏦',
        jobRoles: {},
      ),
      CategoryData(
        name: 'Railways',
        fullName: 'Railway Recruitment Board',
        color: 0xFF00695C,
        icon: '🚂',
        jobRoles: {},
      ),
      CategoryData(
        name: 'Defence',
        fullName: 'Defence Forces Recruitment',
        color: 0xFFD32F2F,
        icon: '⚔️',
        jobRoles: {},
      ),
    ];
  }
}

class CategoryData {
  final String name;
  final String fullName;
  final int color;
  final String icon;
  final Map<String, JobRoleData> jobRoles;

  CategoryData({
    required this.name,
    required this.fullName,
    required this.color,
    required this.icon,
    required this.jobRoles,
  });
}

class JobRoleData {
  final String name;
  final String fullName;
  final List<dynamic> exams;
  final List<ExamDate> upcomingDates;
  final List<dynamic> studyLinks;

  JobRoleData({
    required this.name,
    required this.fullName,
    required this.exams,
    required this.upcomingDates,
    required this.studyLinks,
  });
}

class ExamDate {
  final String event;
  final DateTime date;
  final String status;

  ExamDate({required this.event, required this.date, required this.status});
}
