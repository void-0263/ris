import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_service.dart';

class GeneralKnowledgeScreen extends StatefulWidget {
  const GeneralKnowledgeScreen({super.key});

  @override
  State<GeneralKnowledgeScreen> createState() => _GeneralKnowledgeScreenState();
}

class _GeneralKnowledgeScreenState extends State<GeneralKnowledgeScreen> {
  final ProfileService _profileService = ProfileService();
  String _selectedTopic = 'All';
  String _selectedDifficulty = 'All';
  int _questionsAnswered = 0;
  Future<QuerySnapshot>? _questionsFuture;

  void _loadQuestions() {
    Query query = FirebaseFirestore.instance
        .collection('questions')
        .where('type', isEqualTo: 'gk');
    if (_selectedTopic != 'All') {
      query = query.where('topic', isEqualTo: _selectedTopic);
    }
    if (_selectedDifficulty != 'All') {
      query = query.where('difficulty', isEqualTo: _selectedDifficulty);
    }
    query = query.limit(50);
    setState(() => _questionsFuture = query.get());
  }

  final List<String> _topics = [
    'All',
    'Polity',
    'History',
    'Geography',
    'Science',
    'Economy',
    'Environment',
    'General Knowledge',
    'Awards',
    'Sports',
  ];

  @override
  void initState() {
    super.initState();
    _profileService.startStudySession('GeneralKnowledge');
    _loadQuestions();
  }

  @override
  void dispose() {
    _profileService.endStudySession();
    super.dispose();
  }

  void _onQuestionAnswered() {
    setState(() => _questionsAnswered++);
    _profileService.trackQuestionFaced();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('General Knowledge',
            style: TextStyle(
                fontFamily: 'Ubuntu',
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        backgroundColor: const Color(0xFFE65100),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          if (_questionsAnswered > 0)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text('$_questionsAnswered done',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Ubuntu')),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildTopicFilter(),
          _buildDifficultyFilter(),
          Expanded(child: _buildQuestionsList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFFE65100),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.public_rounded, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('GK Practice',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Ubuntu')),
                Text('Answered today: $_questionsAnswered',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontFamily: 'Ubuntu')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Topic',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey,
                  fontFamily: 'Ubuntu',
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _topics.length,
              itemBuilder: (_, i) {
                final topic = _topics[i];
                final selected = _selectedTopic == topic;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedTopic = topic);
                    _loadQuestions();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFE65100)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(topic,
                        style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Ubuntu',
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : Colors.grey[700])),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          const Text('Difficulty: ',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontFamily: 'Ubuntu',
                  fontWeight: FontWeight.w600)),
          ...['All', 'easy', 'medium', 'hard'].map((d) {
            final selected = _selectedDifficulty == d;
            final colors = {
              'easy': Colors.green,
              'medium': Colors.orange,
              'hard': Colors.red,
              'All': Colors.grey,
            };
            final c = colors[d]!;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedDifficulty = d);
                _loadQuestions();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color:
                      selected ? c.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: selected ? c : Colors.grey.shade200),
                ),
                child: Text(
                  d == 'All' ? 'All' : d[0].toUpperCase() + d.substring(1),
                  style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'Ubuntu',
                      fontWeight: FontWeight.w700,
                      color: selected ? c : Colors.grey[500]),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuestionsList() {
    return FutureBuilder<QuerySnapshot>(
      future: _questionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE65100)));
        }
        if (snapshot.hasError) {
          return _emptyState('Something went wrong',
              'Check your internet connection', Icons.error_outline);
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _emptyState(
            _selectedTopic == 'All'
                ? 'No questions found'
                : 'No questions for "$_selectedTopic"',
            'Try a different topic or difficulty',
            Icons.quiz_outlined,
          );
        }

        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length + 1,
          itemBuilder: (context, i) {
            if (i == docs.length) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 32, top: 8),
                child: Center(
                  child: Text('${docs.length} questions loaded',
                      style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                          fontFamily: 'Ubuntu')),
                ),
              );
            }
            final data = docs[i].data() as Map<String, dynamic>;
            return GKQuestionCard(
              key: ValueKey(docs[i].id),
              data: data,
              docId: docs[i].id,
              index: i + 1,
              onAnswered: _onQuestionAnswered,
            );
          },
        );
      },
    );
  }

  Widget _emptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(title,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                  fontFamily: 'Ubuntu')),
          const SizedBox(height: 8),
          Text(subtitle,
              style: TextStyle(
                  fontSize: 12, color: Colors.grey[400], fontFamily: 'Ubuntu')),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// GK QUESTION CARD
// ─────────────────────────────────────────────────────────
class GKQuestionCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;
  final int index;
  final VoidCallback onAnswered;

  const GKQuestionCard({
    super.key,
    required this.data,
    required this.docId,
    required this.index,
    required this.onAnswered,
  });

  @override
  State<GKQuestionCard> createState() => GKQuestionCardState();
}

class GKQuestionCardState extends State<GKQuestionCard> {
  int? _selectedOption;
  bool _showExplanation = false;

  static const Color _accent = Color(0xFFE65100);

  void _selectOption(int index) {
    if (_selectedOption != null) return;
    setState(() {
      _selectedOption = index;
      _showExplanation = true;
    });
    widget.onAnswered();
    // ✅ FIX: Update stats in questions collection
    FirebaseFirestore.instance
        .collection('questions')
        .doc(widget.docId)
        .update({
      'timesAttempted': FieldValue.increment(1),
      if (index == (widget.data['answer'] as num).toInt())
        'correctAttempts': FieldValue.increment(1),
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final options = (widget.data['options'] as List).cast<String>();
    final correctAnswer = (widget.data['answer'] as num).toInt();
    final difficulty = widget.data['difficulty'] as String? ?? 'medium';
    final topic = widget.data['topic'] as String? ?? '';
    final subtopic = widget.data['subtopic'] as String? ?? '';
    final explanation = widget.data['explanation'] as String? ?? '';
    final examTags = (widget.data['examTags'] as List?)?.cast<String>() ?? [];

    final diffColors = {
      'easy': Colors.green,
      'medium': Colors.orange,
      'hard': Colors.red,
    };
    final diffColor = diffColors[difficulty] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // ── Header ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                      color: _accent, shape: BoxShape.circle),
                  child: Center(
                    child: Text('${widget.index}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Ubuntu')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(topic,
                          style: const TextStyle(
                              fontSize: 12,
                              color: _accent,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Ubuntu')),
                      if (subtopic.isNotEmpty)
                        Text(subtopic,
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                                fontFamily: 'Ubuntu')),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: diffColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(difficulty,
                      style: TextStyle(
                          fontSize: 10,
                          color: diffColor,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Ubuntu')),
                ),
              ],
            ),
          ),

          // ── Exam tags ──
          if (examTags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Wrap(
                spacing: 6,
                children: examTags
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.25)),
                          ),
                          child: Text(tag,
                              style: const TextStyle(
                                  fontSize: 9,
                                  color: Color(0xFFE65100),
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Ubuntu')),
                        ))
                    .toList(),
              ),
            ),

          // ── Question ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Text(widget.data['question'] as String? ?? '',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    fontFamily: 'Ubuntu',
                    height: 1.5)),
          ),

          // ── Options ──
          ...List.generate(options.length, (i) {
            final isSelected = _selectedOption == i;
            final isCorrect = i == correctAnswer;
            final answered = _selectedOption != null;

            Color bg, border;
            Widget? icon;

            if (answered) {
              if (isCorrect) {
                bg = Colors.green.withValues(alpha: 0.08);
                border = Colors.green;
                icon = const Icon(Icons.check_circle_rounded,
                    color: Colors.green, size: 18);
              } else if (isSelected) {
                bg = Colors.red.withValues(alpha: 0.08);
                border = Colors.red;
                icon = const Icon(Icons.cancel_rounded,
                    color: Colors.red, size: 18);
              } else {
                bg = Colors.grey.withValues(alpha: 0.04);
                border = Colors.grey.shade200;
              }
            } else {
              bg = Colors.grey.withValues(alpha: 0.04);
              border = Colors.grey.shade200;
            }

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _selectOption(i),
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: answered && isCorrect
                            ? Colors.green.withValues(alpha: 0.15)
                            : answered && isSelected
                                ? Colors.red.withValues(alpha: 0.15)
                                : _accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(String.fromCharCode(65 + i),
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: answered && isCorrect
                                    ? Colors.green
                                    : answered && isSelected
                                        ? Colors.red
                                        : _accent,
                                fontFamily: 'Ubuntu')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(options[i],
                          style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'Ubuntu',
                              fontWeight: answered && (isCorrect || isSelected)
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: Colors.black87)),
                    ),
                    if (icon != null) icon,
                  ],
                ),
              ),
            );
          }),

          // ── Explanation ──
          if (_showExplanation && explanation.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb_rounded,
                          color: Colors.orange, size: 16),
                      SizedBox(width: 6),
                      Text('Explanation',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE65100),
                              fontFamily: 'Ubuntu')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(explanation,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          fontFamily: 'Ubuntu',
                          height: 1.6)),
                ],
              ),
            )
          else
            const SizedBox(height: 16),
        ],
      ),
    );
  }
}
