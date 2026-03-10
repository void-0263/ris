import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

// ═══════════════════════════════════════════════════════
//  PYQsScreen — Previous Year Questions
// ═══════════════════════════════════════════════════════
class PYQsScreen extends StatefulWidget {
  const PYQsScreen({super.key});

  @override
  State<PYQsScreen> createState() => _PYQsScreenState();
}

class _PYQsScreenState extends State<PYQsScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _selectedExam = 'All';
  String _selectedYear = 'All';
  String _selectedSubject = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late TabController _tabController;

  final List<String> _exams = [
    'All',
    'TNPSC',
    'UPSC',
    'SSC',
    'Banking',
    'Railways',
    'Defence'
  ];

  final List<String> _years = [
    'All',
    '2024',
    '2023',
    '2022',
    '2021',
    '2020',
    '2019',
    '2018'
  ];

  final List<String> _subjects = [
    'All',
    'History',
    'Geography',
    'Polity',
    'Economy',
    'Science',
    'Aptitude',
    'Reasoning',
    'English',
    'General Knowledge',
    'General Awareness',
    'Mathematics',
    'Environment',
    'Algebra',
    'Trigonometry',
    'Calculus',
    'Statistics',
    'Geometry',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text('Previous Year Questions',
            style:
                TextStyle(fontFamily: 'Ubuntu', fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _showFilterSheet(isDark),
            tooltip: 'Filter',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
              fontFamily: 'Ubuntu', fontWeight: FontWeight.w700, fontSize: 14),
          unselectedLabelStyle:
              const TextStyle(fontFamily: 'Ubuntu', fontSize: 13),
          tabs: const [Tab(text: 'Questions'), Tab(text: 'Papers')],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(isDark),
          _buildExamFilter(isDark),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQuestionsTab(isDark),
                _buildPapersTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Bar ──────────────────────────────────────
  Widget _buildSearchBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      child: TextField(
        controller: _searchController,
        style: TextStyle(
            fontFamily: 'Ubuntu',
            color: isDark ? Colors.white : Colors.black87),
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Search questions...',
          hintStyle: TextStyle(
              fontFamily: 'Ubuntu',
              color: isDark ? Colors.white38 : Colors.grey),
          prefixIcon:
              Icon(Icons.search, color: isDark ? Colors.white54 : Colors.grey),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear,
                      color: isDark ? Colors.white54 : Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: isDark ? const Color(0xFF252538) : Colors.grey[100],
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ── Exam Chip Filter ────────────────────────────────
  Widget _buildExamFilter(bool isDark) {
    return Container(
      height: 50,
      color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        itemCount: _exams.length,
        itemBuilder: (_, i) {
          final exam = _exams[i];
          final sel = _selectedExam == exam;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(exam,
                  style: const TextStyle(fontFamily: 'Ubuntu', fontSize: 13)),
              selected: sel,
              onSelected: (_) => setState(() => _selectedExam = exam),
              selectedColor: Colors.blue,
              backgroundColor:
                  isDark ? const Color(0xFF252538) : Colors.grey[200],
              labelStyle: TextStyle(
                fontFamily: 'Ubuntu',
                fontWeight: FontWeight.w600,
                color: sel
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── QUESTIONS TAB ───────────────────────────────────
  Widget _buildQuestionsTab(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredQuestions(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _errorState(snapshot.error.toString(), isDark);
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.blue));
        }

        var docs = snapshot.data?.docs ?? [];

        // Client-side search filter
        if (_searchQuery.isNotEmpty) {
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final q = (data['question'] ?? '').toString().toLowerCase();
            final s = (data['subject'] ?? '').toString().toLowerCase();
            return q.contains(_searchQuery) || s.contains(_searchQuery);
          }).toList();
        }

        if (docs.isEmpty) return _emptyState('No questions found', isDark);

        return Column(
          children: [
            _buildResultCount(docs.length, isDark),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  return _buildQuestionCard(data, i + 1, isDark);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Stream<QuerySnapshot> _getFilteredQuestions() {
    Query q = _db.collection('pyqs');
    if (_selectedExam != 'All') q = q.where('exam', isEqualTo: _selectedExam);
    if (_selectedYear != 'All') q = q.where('year', isEqualTo: _selectedYear);
    if (_selectedSubject != 'All')
      q = q.where('subject', isEqualTo: _selectedSubject);
    return q.limit(1000).snapshots();
  }

  Widget _buildResultCount(int count, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? const Color(0xFF1A1A2E) : Colors.blue.shade50,
      child: Row(
        children: [
          Icon(Icons.quiz_rounded, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 6),
          Text(
            '$count question${count != 1 ? 's' : ''} found',
            style: TextStyle(
                fontFamily: 'Ubuntu',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.blue.shade700),
          ),
          const Spacer(),
          if (_selectedYear != 'All' || _selectedSubject != 'All')
            GestureDetector(
              onTap: () => setState(() {
                _selectedYear = 'All';
                _selectedSubject = 'All';
              }),
              child: Row(
                children: [
                  Icon(Icons.close_rounded,
                      size: 14, color: Colors.blue.shade700),
                  const SizedBox(width: 4),
                  Text('Clear filters',
                      style: TextStyle(
                          fontFamily: 'Ubuntu',
                          fontSize: 12,
                          color: Colors.blue.shade700)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> data, int num, bool isDark) {
    final options = List<String>.from(data['options'] ?? []);
    final correctIdx = data['answer'] as int? ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E30) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: _PYQQuestionTile(
        num: num,
        data: data,
        options: options,
        correctIdx: correctIdx,
        year: data['year']?.toString() ?? '',
        exam: data['exam']?.toString() ?? '',
        subject: data['subject']?.toString() ?? '',
        isDark: isDark,
      ),
    );
  }

  // ── PAPERS TAB ──────────────────────────────────────
  // ✅ FIX 1: Removed .orderBy to avoid index error
  Widget _buildPapersTab(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('pyqPapers').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _errorState(snapshot.error.toString(), isDark);
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.blue));
        }

        var docs = snapshot.data?.docs ?? [];

        if (_selectedExam != 'All') {
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return data['exam'] == _selectedExam;
          }).toList();
        }

        if (docs.isEmpty) return _emptyState('No papers found', isDark);

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _buildPaperCard(data, isDark);
          },
        );
      },
    );
  }

  Widget _buildPaperCard(Map<String, dynamic> data, bool isDark) {
    final exam = data['exam']?.toString() ?? '';
    final year = data['year']?.toString() ?? '';
    final title = data['title']?.toString() ?? '$exam $year Paper';
    final totalQ = data['totalQuestions'] ?? 0;
    final totalMarks = data['totalMarks'] ?? 0;
    final subjects = List<String>.from(data['subjects'] ?? []);
    final paperId = data['paperId']?.toString() ?? '';
    final examPattern = data['examPattern']?.toString() ?? '';
    final difficulty = data['difficulty']?.toString() ?? 'Medium';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E30) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: InkWell(
        onTap: () => _openPaper(data, isDark),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _examBadge(exam),
                  const SizedBox(width: 8),
                  _yearBadge(year, isDark),
                  const SizedBox(width: 8),
                  _difficultyBadge(difficulty),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$totalQ Qs',
                      style: const TextStyle(
                          fontFamily: 'Ubuntu',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.blue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                    fontFamily: 'Ubuntu',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87),
              ),
              if (data['description'] != null) ...[
                const SizedBox(height: 6),
                Text(
                  data['description'],
                  style: TextStyle(
                      fontFamily: 'Ubuntu',
                      fontSize: 13,
                      color: isDark ? Colors.white60 : Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (examPattern.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 14,
                        color: isDark ? Colors.white38 : Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        examPattern,
                        style: TextStyle(
                            fontFamily: 'Ubuntu',
                            fontSize: 12,
                            color:
                                isDark ? Colors.white38 : Colors.grey.shade500),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  _infoChip(Icons.quiz_rounded, '$totalQ Questions', isDark),
                  const SizedBox(width: 8),
                  _infoChip(Icons.star_rounded, '$totalMarks Marks', isDark),
                ],
              ),
              if (subjects.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: subjects
                      .map((s) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(s,
                                style: const TextStyle(
                                    fontFamily: 'Ubuntu',
                                    fontSize: 11,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600)),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openPaper(data, isDark),
                      icon: const Icon(Icons.visibility_rounded, size: 16),
                      label: const Text('View Questions',
                          style: TextStyle(fontFamily: 'Ubuntu')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: BorderSide(color: Colors.blue.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: paperId.isNotEmpty
                          ? () => _practiceNow(data, paperId)
                          : null,
                      icon: const Icon(Icons.play_arrow_rounded, size: 16),
                      label: const Text('Practice',
                          style: TextStyle(
                              fontFamily: 'Ubuntu',
                              fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Filter Bottom Sheet ─────────────────────────────
  void _showFilterSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E30) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Text('Filter Questions',
                    style: TextStyle(
                        fontFamily: 'Ubuntu',
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 20),
                _filterLabel('Year', isDark),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _years
                      .map((y) => ChoiceChip(
                            label: Text(y,
                                style: const TextStyle(
                                    fontFamily: 'Ubuntu', fontSize: 13)),
                            selected: _selectedYear == y,
                            onSelected: (_) {
                              setModal(() => _selectedYear = y);
                              setState(() => _selectedYear = y);
                            },
                            selectedColor: Colors.blue,
                            backgroundColor: isDark
                                ? const Color(0xFF252538)
                                : Colors.grey[200],
                            labelStyle: TextStyle(
                                fontFamily: 'Ubuntu',
                                fontWeight: FontWeight.w600,
                                color: _selectedYear == y
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.white70
                                        : Colors.black87)),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 20),
                _filterLabel('Subject', isDark),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _subjects
                      .map((s) => ChoiceChip(
                            label: Text(s,
                                style: const TextStyle(
                                    fontFamily: 'Ubuntu', fontSize: 12)),
                            selected: _selectedSubject == s,
                            onSelected: (_) {
                              setModal(() => _selectedSubject = s);
                              setState(() => _selectedSubject = s);
                            },
                            selectedColor: Colors.blue,
                            backgroundColor: isDark
                                ? const Color(0xFF252538)
                                : Colors.grey[200],
                            labelStyle: TextStyle(
                                fontFamily: 'Ubuntu',
                                fontWeight: FontWeight.w600,
                                color: _selectedSubject == s
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.white70
                                        : Colors.black87)),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setModal(() {
                            _selectedYear = 'All';
                            _selectedSubject = 'All';
                          });
                          setState(() {
                            _selectedYear = 'All';
                            _selectedSubject = 'All';
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Reset',
                            style: TextStyle(fontFamily: 'Ubuntu')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Apply',
                            style: TextStyle(
                                fontFamily: 'Ubuntu',
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────
  Widget _filterLabel(String text, bool isDark) => Text(text,
      style: TextStyle(
          fontFamily: 'Ubuntu',
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: isDark ? Colors.white70 : Colors.black54));

  Widget _examBadge(String exam) {
    const colors = {
      'TNPSC': Color(0xFF8B4513),
      'UPSC': Color(0xFF1565C0),
      'SSC': Color(0xFF6A1B9A),
      'Banking': Color(0xFF2E7D32),
      'Railways': Color(0xFFC62828),
      'Defence': Color(0xFFE65100),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: colors[exam] ?? Colors.grey.shade700,
          borderRadius: BorderRadius.circular(6)),
      child: Text(exam,
          style: const TextStyle(
              fontFamily: 'Ubuntu',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white)),
    );
  }

  Widget _yearBadge(String year, bool isDark) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252538) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(year,
            style: TextStyle(
                fontFamily: 'Ubuntu',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : Colors.black54)),
      );

  Widget _difficultyBadge(String difficulty) {
    final color = difficulty == 'Hard'
        ? Colors.red
        : difficulty == 'Easy'
            ? Colors.green
            : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6)),
      child: Text(difficulty,
          style: TextStyle(
              fontFamily: 'Ubuntu',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color)),
    );
  }

  Widget _infoChip(IconData icon, String label, bool isDark) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252538) : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.blue.shade600),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Ubuntu',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade600)),
          ],
        ),
      );

  Widget _emptyState(String msg, bool isDark) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_edu_rounded,
                size: 80,
                color: isDark ? Colors.white24 : Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(msg,
                style: TextStyle(
                    fontFamily: 'Ubuntu',
                    fontSize: 16,
                    color: isDark ? Colors.white60 : Colors.grey.shade600)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() {
                _selectedExam = 'All';
                _selectedYear = 'All';
                _selectedSubject = 'All';
                _searchController.clear();
                _searchQuery = '';
              }),
              child: const Text('Clear all filters',
                  style: TextStyle(fontFamily: 'Ubuntu', color: Colors.blue)),
            ),
          ],
        ),
      );

  Widget _errorState(String error, bool isDark) => Center(
        child: Text('Error: $error',
            style: const TextStyle(fontFamily: 'Ubuntu', color: Colors.red)),
      );

  void _openPaper(Map<String, dynamic> data, bool isDark) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PYQPaperScreen(paperData: data),
      ),
    );
  }

  void _practiceNow(Map<String, dynamic> data, String paperId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PYQPracticeScreen(paperData: data, paperId: paperId),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  PYQPaperScreen — View all questions of a paper
//  ✅ FIX 2: Removed .orderBy, sorts in code instead
// ═══════════════════════════════════════════════════════
class PYQPaperScreen extends StatelessWidget {
  final Map<String, dynamic> paperData;

  const PYQPaperScreen({super.key, required this.paperData});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paperId = paperData['paperId']?.toString() ?? '';
    final title = paperData['title']?.toString() ?? 'Paper';

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: Text(title,
            style: const TextStyle(
                fontFamily: 'Ubuntu', fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PYQPracticeScreen(paperData: paperData, paperId: paperId),
                ),
              );
            },
            icon: const Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: 18),
            label: const Text('Practice',
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Ubuntu',
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pyqs')
            .where('paperId', isEqualTo: paperId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.blue));
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)));
          }

          var docs = snapshot.data?.docs ?? [];

          // ✅ FIX: Sort by order field in code instead of Firestore
          docs.sort((a, b) {
            final orderA = (a.data() as Map)['order'] ?? 0;
            final orderB = (b.data() as Map)['order'] ?? 0;
            return orderA.compareTo(orderB);
          });

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_edu_rounded,
                      size: 64,
                      color: isDark ? Colors.white24 : Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No questions for this paper yet',
                      style: TextStyle(
                          fontFamily: 'Ubuntu',
                          fontSize: 15,
                          color:
                              isDark ? Colors.white60 : Colors.grey.shade600)),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: isDark ? const Color(0xFF1A1A2E) : Colors.blue.shade50,
                child: Row(
                  children: [
                    Icon(Icons.quiz_rounded,
                        size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 6),
                    Text('${docs.length} questions',
                        style: TextStyle(
                            fontFamily: 'Ubuntu',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue.shade700)),
                    const Spacer(),
                    if (paperData['totalMarks'] != null)
                      Text('${paperData['totalMarks']} marks',
                          style: TextStyle(
                              fontFamily: 'Ubuntu',
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white60
                                  : Colors.grey.shade600)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final options = List<String>.from(data['options'] ?? []);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E30) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 3))
                        ],
                      ),
                      child: _PYQQuestionTile(
                        num: i + 1,
                        data: data,
                        options: options,
                        correctIdx: data['answer'] as int? ?? 0,
                        year: data['year']?.toString() ?? '',
                        exam: data['exam']?.toString() ?? '',
                        subject: data['subject']?.toString() ?? '',
                        isDark: isDark,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  PYQPracticeScreen — Timed practice mode for a paper
//  ✅ FIX 3: Removed .orderBy, sorts in code instead
// ═══════════════════════════════════════════════════════
class PYQPracticeScreen extends StatefulWidget {
  final Map<String, dynamic> paperData;
  final String paperId;

  const PYQPracticeScreen(
      {super.key, required this.paperData, required this.paperId});

  @override
  State<PYQPracticeScreen> createState() => _PYQPracticeScreenState();
}

class _PYQPracticeScreenState extends State<PYQPracticeScreen> {
  List<Map<String, dynamic>> _questions = [];
  int _currentIndex = 0;
  Map<int, int> _answers = {};
  Map<int, bool> _marked = {};
  bool _isLoading = true;
  bool _isSubmitted = false;
  bool _showExplanation = false;

  Timer? _timer;
  late int _remainingSeconds;

  @override
  void initState() {
    super.initState();
    final totalQ = widget.paperData['totalQuestions'] ?? 60;
    _remainingSeconds = (totalQ * 1.5 * 60).toInt();
    _loadQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('pyqs')
          .where('paperId', isEqualTo: widget.paperId)
          .get();

      // ✅ FIX: Sort by order field in code instead
      final docs = snap.docs;
      docs.sort((a, b) {
        final orderA = (a.data()['order'] ?? 0) as int;
        final orderB = (b.data()['order'] ?? 0) as int;
        return orderA.compareTo(orderB);
      });

      setState(() {
        _questions = docs.map((d) => d.data()).toList();
        _isLoading = false;
      });
      _startTimer();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _submitTest(autoSubmit: true);
      }
    });
  }

  String _formatTime(int secs) {
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (_remainingSeconds <= 300) return Colors.red;
    if (_remainingSeconds <= 600) return Colors.orange;
    return Colors.green;
  }

  void _submitTest({bool autoSubmit = false}) {
    _timer?.cancel();
    if (!autoSubmit) {
      final unanswered = _questions.length - _answers.length;
      if (unanswered > 0) {
        _showConfirm(unanswered);
        return;
      }
    }
    setState(() {
      _isSubmitted = true;
      _currentIndex = 0;
    });
  }

  void _showConfirm(int unanswered) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E30) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Submit Test?',
            style:
                TextStyle(fontFamily: 'Ubuntu', fontWeight: FontWeight.w700)),
        content: Text(
            '$unanswered question${unanswered > 1 ? 's' : ''} unanswered.\nSubmit anyway?',
            style: const TextStyle(fontFamily: 'Ubuntu')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back',
                  style: TextStyle(fontFamily: 'Ubuntu'))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isSubmitted = true;
                _currentIndex = 0;
              });
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Submit',
                style: TextStyle(
                    fontFamily: 'Ubuntu', fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateResults() {
    double score = 0;
    int correct = 0, wrong = 0, skipped = 0;

    for (int i = 0; i < _questions.length; i++) {
      final correctAns = _questions[i]['answer'] as int? ?? 0;
      if (_answers.containsKey(i)) {
        if (_answers[i] == correctAns) {
          score += 2;
          correct++;
        } else {
          wrong++;
        }
      } else {
        skipped++;
      }
    }

    final total = _questions.length * 2.0;
    return {
      'score': score,
      'correct': correct,
      'wrong': wrong,
      'skipped': skipped,
      'total': _questions.length,
      'percentage': total > 0 ? (score / total * 100) : 0.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F9FA),
        body:
            const Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          title: const Text('Practice',
              style:
                  TextStyle(fontFamily: 'Ubuntu', fontWeight: FontWeight.w700)),
        ),
        body: Center(
          child: Text('No questions available for practice.',
              style: TextStyle(
                  fontFamily: 'Ubuntu',
                  color: isDark ? Colors.white60 : Colors.grey)),
        ),
      );
    }

    if (_isSubmitted) return _buildResultScreen(isDark);
    return _buildTestScreen(isDark);
  }

  Widget _buildTestScreen(bool isDark) {
    final q = _questions[_currentIndex];
    final options = List<String>.from(q['options'] ?? []);
    final correctIdx = q['answer'] as int? ?? 0;
    final selectedOpt = _answers[_currentIndex];
    final isMarked = _marked[_currentIndex] ?? false;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => _submitTest(),
        ),
        title: Text(
          'Q ${_currentIndex + 1} / ${_questions.length}',
          style: const TextStyle(
              fontFamily: 'Ubuntu', fontWeight: FontWeight.w700, fontSize: 16),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _timerColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.timer_rounded, size: 16, color: _timerColor),
                const SizedBox(width: 4),
                Text(
                  _formatTime(_remainingSeconds),
                  style: TextStyle(
                      fontFamily: 'Ubuntu',
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: _timerColor),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _questions.length,
            backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 4,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (q['subject'] != null)
                        _badge(q['subject'], Colors.blue.withOpacity(0.1),
                            Colors.blue, isDark),
                      const SizedBox(width: 8),
                      if (q['year'] != null)
                        _badge(
                            q['year'].toString(),
                            isDark
                                ? const Color(0xFF252538)
                                : Colors.grey.shade200,
                            isDark ? Colors.white60 : Colors.black54,
                            isDark),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _marked[_currentIndex] = !isMarked);
                        },
                        child: Icon(
                          isMarked
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: isMarked ? Colors.orange : Colors.grey,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    q['question'] ?? '',
                    style: TextStyle(
                        fontFamily: 'Ubuntu',
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                        height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  ...options.asMap().entries.map((e) {
                    final isSelected = selectedOpt == e.key;
                    final isCorrect = e.key == correctIdx;
                    final hasAnswered = selectedOpt != null;

                    Color bg = isDark ? const Color(0xFF1E1E30) : Colors.white;
                    Color textColor = isDark ? Colors.white70 : Colors.black87;
                    Color borderColor =
                        isDark ? const Color(0xFF2A2A40) : Colors.grey.shade200;

                    if (hasAnswered) {
                      if (isCorrect) {
                        bg = Colors.green.withOpacity(0.13);
                        textColor = Colors.green;
                        borderColor = Colors.green.withOpacity(0.5);
                      } else if (isSelected && !isCorrect) {
                        bg = Colors.red.withOpacity(0.1);
                        textColor = Colors.red;
                        borderColor = Colors.red.withOpacity(0.4);
                      }
                    } else if (isSelected) {
                      bg = Colors.blue.withOpacity(0.12);
                      textColor = Colors.blue;
                      borderColor = Colors.blue.withOpacity(0.5);
                    }

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _answers[_currentIndex] = e.key;
                          _showExplanation = false;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: isSelected
                                        ? Colors.blue
                                        : (isDark
                                            ? Colors.white30
                                            : Colors.grey.shade400)),
                              ),
                              child: Center(
                                child: Text(
                                  String.fromCharCode(65 + e.key),
                                  style: TextStyle(
                                      fontFamily: 'Ubuntu',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? Colors.white
                                          : textColor),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(e.value,
                                  style: TextStyle(
                                      fontFamily: 'Ubuntu',
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: textColor)),
                            ),
                            if (hasAnswered && isCorrect)
                              const Icon(Icons.check_circle_rounded,
                                  color: Colors.green, size: 18),
                            if (hasAnswered && isSelected && !isCorrect)
                              const Icon(Icons.cancel_rounded,
                                  color: Colors.red, size: 18),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  if (_answers.containsKey(_currentIndex) &&
                      q['explanation'] != null) ...[
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _showExplanation = !_showExplanation),
                      icon: Icon(
                          _showExplanation
                              ? Icons.visibility_off_rounded
                              : Icons.lightbulb_rounded,
                          size: 16),
                      label: Text(
                          _showExplanation
                              ? 'Hide Explanation'
                              : 'Show Explanation',
                          style: const TextStyle(fontFamily: 'Ubuntu')),
                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                    ),
                    if (_showExplanation) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: Colors.blue.withOpacity(0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('💡 ', style: TextStyle(fontSize: 14)),
                            Expanded(
                              child: Text(q['explanation'],
                                  style: TextStyle(
                                      fontFamily: 'Ubuntu',
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                      height: 1.5)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -3))
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _currentIndex > 0
                      ? () => setState(() {
                            _currentIndex--;
                            _showExplanation = false;
                          })
                      : null,
                  icon: const Icon(Icons.arrow_back_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        isDark ? const Color(0xFF252538) : Colors.grey.shade100,
                    foregroundColor: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Q ${_currentIndex + 1} of ${_questions.length}',
                        style: TextStyle(
                            fontFamily: 'Ubuntu',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_answers.length} answered · ${_marked.values.where((v) => v).length} marked',
                        style: TextStyle(
                            fontFamily: 'Ubuntu',
                            fontSize: 11,
                            color: isDark ? Colors.white38 : Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _currentIndex < _questions.length - 1
                    ? ElevatedButton.icon(
                        onPressed: () => setState(() {
                          _currentIndex++;
                          _showExplanation = false;
                        }),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text('Next',
                            style: TextStyle(
                                fontFamily: 'Ubuntu',
                                fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () => _submitTest(),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Submit',
                            style: TextStyle(
                                fontFamily: 'Ubuntu',
                                fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen(bool isDark) {
    final results = _calculateResults();
    final pct = (results['percentage'] as double).toStringAsFixed(1);
    final score = (results['score'] as num).toStringAsFixed(0);
    final correct = results['correct'] as int;
    final wrong = results['wrong'] as int;
    final skipped = results['skipped'] as int;
    final passed = (results['percentage'] as double) >= 50;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text('Results',
            style:
                TextStyle(fontFamily: 'Ubuntu', fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done',
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Ubuntu',
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (passed ? Colors.green : Colors.red).withOpacity(0.1),
                border: Border.all(
                    color: passed ? Colors.green : Colors.red, width: 4),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$pct%',
                      style: TextStyle(
                          fontFamily: 'Ubuntu',
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: passed ? Colors.green : Colors.red)),
                  Text(passed ? '✅ Passed' : '❌ Failed',
                      style: TextStyle(
                          fontFamily: 'Ubuntu',
                          fontSize: 13,
                          color: passed ? Colors.green : Colors.red)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(widget.paperData['title'] ?? 'Practice Result',
                style: TextStyle(
                    fontFamily: 'Ubuntu',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Row(
              children: [
                _statCard('Correct', '$correct', Colors.green, isDark),
                const SizedBox(width: 8),
                _statCard('Wrong', '$wrong', Colors.red, isDark),
                const SizedBox(width: 8),
                _statCard('Skipped', '$skipped', Colors.grey, isDark),
                const SizedBox(width: 8),
                _statCard('Score', score, Colors.blue, isDark),
              ],
            ),
            const SizedBox(height: 24),
            Text('Review Answers',
                style: TextStyle(
                    fontFamily: 'Ubuntu',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 12),
            ...List.generate(_questions.length, (i) {
              final q = _questions[i];
              final options = List<String>.from(q['options'] ?? []);
              final correctAns = q['answer'] as int? ?? 0;
              final userAns = _answers[i];
              final isCorrect = userAns == correctAns;
              final isSkipped = !_answers.containsKey(i);
              final headerColor = isSkipped
                  ? Colors.grey
                  : isCorrect
                      ? Colors.green
                      : Colors.red;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E30) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: headerColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: headerColor.withOpacity(0.1),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                              isSkipped
                                  ? Icons.remove_circle_outline
                                  : isCorrect
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_rounded,
                              color: headerColor,
                              size: 18),
                          const SizedBox(width: 8),
                          Text(
                              'Q${i + 1} — ${isSkipped ? 'Skipped' : isCorrect ? 'Correct' : 'Incorrect'}',
                              style: TextStyle(
                                  fontFamily: 'Ubuntu',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: headerColor)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(q['question'] ?? '',
                              style: TextStyle(
                                  fontFamily: 'Ubuntu',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isDark ? Colors.white : Colors.black87)),
                          const SizedBox(height: 10),
                          ...options.asMap().entries.map((e) {
                            final isCor = e.key == correctAns;
                            final isUser = e.key == userAns;
                            Color bg = isDark
                                ? const Color(0xFF252538)
                                : Colors.grey.shade100;
                            Color tc = isDark ? Colors.white70 : Colors.black54;
                            if (isCor) {
                              bg = Colors.green.withOpacity(0.15);
                              tc = Colors.green;
                            } else if (isUser && !isCor) {
                              bg = Colors.red.withOpacity(0.12);
                              tc = Colors.red;
                            }
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                children: [
                                  Text('${String.fromCharCode(65 + e.key)}. ',
                                      style: TextStyle(
                                          fontFamily: 'Ubuntu',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: tc)),
                                  Expanded(
                                      child: Text(e.value,
                                          style: TextStyle(
                                              fontFamily: 'Ubuntu',
                                              fontSize: 13,
                                              color: tc))),
                                  if (isCor)
                                    const Icon(Icons.check_circle_rounded,
                                        color: Colors.green, size: 16),
                                  if (isUser && !isCor)
                                    const Icon(Icons.cancel_rounded,
                                        color: Colors.red, size: 16),
                                ],
                              ),
                            );
                          }),
                          if (q['explanation'] != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.blue.withOpacity(0.2)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('💡 ',
                                      style: TextStyle(fontSize: 13)),
                                  Expanded(
                                    child: Text(q['explanation'],
                                        style: TextStyle(
                                            fontFamily: 'Ubuntu',
                                            fontSize: 12,
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black87,
                                            height: 1.4)),
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
              );
            }),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Back to Home',
                    style: TextStyle(
                        fontFamily: 'Ubuntu', fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontFamily: 'Ubuntu',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: color)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Ubuntu',
                    fontSize: 10,
                    color: isDark ? Colors.white60 : Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color bg, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text,
          style: TextStyle(
              fontFamily: 'Ubuntu',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor)),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  _PYQQuestionTile — expandable question card
// ═══════════════════════════════════════════════════════
class _PYQQuestionTile extends StatefulWidget {
  final int num;
  final Map<String, dynamic> data;
  final List<String> options;
  final int correctIdx;
  final String year, exam, subject;
  final bool isDark;

  const _PYQQuestionTile({
    required this.num,
    required this.data,
    required this.options,
    required this.correctIdx,
    required this.year,
    required this.exam,
    required this.subject,
    required this.isDark,
  });

  @override
  State<_PYQQuestionTile> createState() => _PYQQuestionTileState();
}

class _PYQQuestionTileState extends State<_PYQQuestionTile> {
  bool _expanded = false;
  int? _selectedOption;
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _expanded = !_expanded);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.15),
                          shape: BoxShape.circle),
                      child: Center(
                        child: Text('${widget.num}',
                            style: const TextStyle(
                                fontFamily: 'Ubuntu',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.blue)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(widget.data['question'] ?? '',
                          style: TextStyle(
                              fontFamily: 'Ubuntu',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color:
                                  widget.isDark ? Colors.white : Colors.black87,
                              height: 1.4)),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: widget.isDark
                            ? Colors.white38
                            : Colors.grey.shade400),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (widget.year.isNotEmpty)
                      _badge(
                          widget.year,
                          widget.isDark
                              ? const Color(0xFF252538)
                              : Colors.grey.shade200,
                          widget.isDark ? Colors.white60 : Colors.black54),
                    if (widget.year.isNotEmpty) const SizedBox(width: 6),
                    if (widget.exam.isNotEmpty)
                      _badge(widget.exam, Colors.blue.withOpacity(0.12),
                          Colors.blue),
                    if (widget.subject.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      _badge(widget.subject, Colors.green.withOpacity(0.1),
                          Colors.green),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          Divider(
              height: 1,
              color: widget.isDark
                  ? const Color(0xFF2A2A40)
                  : Colors.grey.shade100),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...widget.options.asMap().entries.map((e) {
                  final isCorrect = e.key == widget.correctIdx;
                  final isSelected = _selectedOption == e.key;
                  Color bg = widget.isDark
                      ? const Color(0xFF252538)
                      : Colors.grey.shade50;
                  Color tc = widget.isDark ? Colors.white70 : Colors.black54;
                  Color border = Colors.transparent;

                  if (_revealed) {
                    if (isCorrect) {
                      bg = Colors.green.withOpacity(0.15);
                      tc = Colors.green;
                      border = Colors.green.withOpacity(0.4);
                    } else if (isSelected && !isCorrect) {
                      bg = Colors.red.withOpacity(0.1);
                      tc = Colors.red;
                      border = Colors.red.withOpacity(0.3);
                    }
                  } else if (isSelected) {
                    bg = Colors.blue.withOpacity(0.1);
                    tc = Colors.blue;
                    border = Colors.blue.withOpacity(0.4);
                  }

                  return GestureDetector(
                    onTap: () {
                      if (_revealed) return;
                      HapticFeedback.lightImpact();
                      setState(() => _selectedOption = e.key);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: border, width: 1.5)),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: isSelected || (_revealed && isCorrect)
                                  ? tc.withOpacity(0.15)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(color: tc.withOpacity(0.5)),
                            ),
                            child: Center(
                                child: Text(String.fromCharCode(65 + e.key),
                                    style: TextStyle(
                                        fontFamily: 'Ubuntu',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: tc))),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(e.value,
                                  style: TextStyle(
                                      fontFamily: 'Ubuntu',
                                      fontSize: 14,
                                      color: tc))),
                          if (_revealed && isCorrect)
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.green, size: 18),
                          if (_revealed && isSelected && !isCorrect)
                            const Icon(Icons.cancel_rounded,
                                color: Colors.red, size: 18),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: () => setState(() => _revealed = !_revealed),
                  icon: Icon(
                      _revealed
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 16),
                  label: Text(_revealed ? 'Hide Answer' : 'Reveal Answer',
                      style: const TextStyle(fontFamily: 'Ubuntu')),
                  style: TextButton.styleFrom(foregroundColor: Colors.blue),
                ),
                if (_revealed && widget.data['explanation'] != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💡 ', style: TextStyle(fontSize: 14)),
                        Expanded(
                          child: Text(widget.data['explanation'],
                              style: TextStyle(
                                  fontFamily: 'Ubuntu',
                                  fontSize: 13,
                                  color: widget.isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                  height: 1.5)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _badge(String text, Color bg, Color textColor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Text(text,
            style: TextStyle(
                fontFamily: 'Ubuntu',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor)),
      );
}
