import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

// ════════════════════════════════════════════════════
//  MockTestScreen — Full test-taking experience
// ═══════════════════════════════════════════════════════
class MockTestScreen extends StatefulWidget {
  final String testId;
  final Map<String, dynamic> testData;

  const MockTestScreen({
    super.key,
    required this.testId,
    required this.testData,
  });

  @override
  State<MockTestScreen> createState() => _MockTestScreenState();
}

class _MockTestScreenState extends State<MockTestScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── State ──
  List<Map<String, dynamic>> _questions = [];
  int _currentIndex = 0;
  Map<int, int> _answers = {}; // questionIndex → selectedOption
  Map<int, bool> _marked = {}; // questionIndex → marked for review
  bool _isLoading = true;
  bool _isSubmitted = false;

  // ── Timer ──
  Timer? _timer;
  late int _remainingSeconds;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = (widget.testData['duration'] ?? 60) * 60;
    _loadQuestions();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── Load questions from Firestore subcollection ──
  Future<void> _loadQuestions() async {
    try {
      final snap = await _db
          .collection('mockTests')
          .doc(widget.testId)
          .collection('questions')
          .orderBy('order')
          .get();

      setState(() {
        _questions = snap.docs.map((d) => d.data()).toList();
        _isLoading = false;
      });
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

  Color _timerColor() {
    if (_remainingSeconds <= 300) return Colors.red;
    if (_remainingSeconds <= 600) return Colors.orange;
    return Colors.green;
  }

  void _selectAnswer(int optionIndex) {
    if (_isSubmitted) return;
    HapticFeedback.lightImpact();
    setState(() => _answers[_currentIndex] = optionIndex);
  }

  void _toggleMark() {
    HapticFeedback.lightImpact();
    setState(() => _marked[_currentIndex] = !(_marked[_currentIndex] ?? false));
  }

  void _goTo(int index) {
    if (index < 0 || index >= _questions.length) return;
    setState(() => _currentIndex = index);
  }

  void _submitTest({bool autoSubmit = false}) {
    _timer?.cancel();
    if (!autoSubmit) {
      final unanswered = _questions.length - _answers.length;
      if (unanswered > 0) {
        _showSubmitConfirmation(unanswered);
        return;
      }
    }
    setState(() => _isSubmitted = true);
    _showResults();
  }

  void _showSubmitConfirmation(int unanswered) {
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
          '$unanswered question${unanswered > 1 ? 's' : ''} unanswered.\nAre you sure you want to submit?',
          style: const TextStyle(fontFamily: 'Ubuntu', fontSize: 15),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back',
                  style: TextStyle(fontFamily: 'Ubuntu'))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isSubmitted = true);
              _showResults();
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

  // ── Calculate score ──
  Map<String, dynamic> _calculateResults() {
    double score = 0;
    int correct = 0, wrong = 0, skipped = 0;
    final double negRatio =
        (widget.testData['negativeMarkingRatio'] ?? 0.33).toDouble();
    final bool hasNegative = widget.testData['negativeMarking'] == true;

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final correctAns = q['answer'] as int? ?? 0;
      if (_answers.containsKey(i)) {
        if (_answers[i] == correctAns) {
          score += 2;
          correct++;
        } else {
          if (hasNegative) score -= (2 * negRatio);
          wrong++;
        }
      } else {
        skipped++;
      }
    }

    final total = _questions.length * 2.0;
    final pct = total > 0 ? (score / total * 100) : 0;

    return {
      'score': score.toStringAsFixed(2),
      'correct': correct,
      'wrong': wrong,
      'skipped': skipped,
      'total': _questions.length,
      'percentage': pct.toStringAsFixed(1),
      'passed': score >= (widget.testData['passingMarks'] ?? 0),
    };
  }

  void _showResults() {
    final results = _calculateResults();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MockTestResultScreen(
          testData: widget.testData,
          questions: _questions,
          answers: _answers,
          results: results,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════
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
        appBar: AppBar(title: const Text('Mock Test')),
        body: const Center(
            child: Text('No questions found.',
                style: TextStyle(fontFamily: 'Ubuntu'))),
      );
    }

    final q = _questions[_currentIndex];
    final options = List<String>.from(q['options'] ?? []);
    final selectedOption = _answers[_currentIndex];
    final isMarked = _marked[_currentIndex] ?? false;

    return WillPopScope(
      onWillPop: () async {
        if (!_isSubmitted) {
          _showExitConfirmation();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F9FA),
        appBar: _buildAppBar(isDark, isMarked),
        body: Column(
          children: [
            _buildProgressBar(isDark),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuestionCard(q, isDark),
                    const SizedBox(height: 16),
                    ...options.asMap().entries.map((e) => _buildOptionTile(
                        e.key, e.value, selectedOption, isDark)),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildBottomNav(isDark),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, bool isMarked) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => _showExitConfirmation(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.testData['title'] ?? 'Mock Test',
            style: const TextStyle(
                fontFamily: 'Ubuntu',
                fontWeight: FontWeight.w700,
                fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Q ${_currentIndex + 1} of ${_questions.length}',
            style: const TextStyle(fontSize: 12, fontFamily: 'Ubuntu'),
          ),
        ],
      ),
      actions: [
        // Bookmark/Mark for review
        IconButton(
          icon: Icon(isMarked ? Icons.bookmark : Icons.bookmark_border,
              color: isMarked ? Colors.yellow : Colors.white),
          onPressed: _toggleMark,
          tooltip: 'Mark for review',
        ),
        // Timer
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _timerColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _timerColor(), width: 1.5),
          ),
          child: Row(
            children: [
              Icon(Icons.timer, size: 14, color: _timerColor()),
              const SizedBox(width: 4),
              Text(_formatTime(_remainingSeconds),
                  style: TextStyle(
                      fontFamily: 'Ubuntu',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: _timerColor())),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(bool isDark) {
    final answered = _answers.length;
    final progress = _questions.isNotEmpty ? answered / _questions.length : 0.0;
    return Container(
      height: 4,
      color: isDark ? const Color(0xFF1A1A2E) : Colors.blue.shade50,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Colors.blue, Colors.lightBlueAccent]),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> q, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E30) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topic badge
          if (q['topic'] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(q['topic'],
                  style: const TextStyle(
                      fontFamily: 'Ubuntu',
                      fontSize: 11,
                      color: Colors.blue,
                      fontWeight: FontWeight.w600)),
            ),
          const SizedBox(height: 14),
          Text(
            q['q'] ?? q['question'] ?? '',
            style: TextStyle(
                fontFamily: 'Ubuntu',
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
                height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
      int index, String option, int? selected, bool isDark) {
    final isSelected = selected == index;

    Color borderColor = isDark ? const Color(0xFF2A2A40) : Colors.grey.shade200;
    Color bgColor = isDark ? const Color(0xFF1E1E30) : Colors.white;
    Color textColor = isDark ? Colors.white : Colors.black87;
    Color labelColor = isDark ? Colors.white60 : Colors.grey;

    if (isSelected) {
      borderColor = Colors.blue;
      bgColor = Colors.blue.withOpacity(isDark ? 0.2 : 0.08);
      textColor = Colors.blue;
      labelColor = Colors.blue;
    }

    return GestureDetector(
      onTap: () => _selectAnswer(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            // Option label (A, B, C, D)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blue
                      : (isDark
                          ? const Color(0xFF252538)
                          : Colors.grey.shade100),
                  shape: BoxShape.circle),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index),
                  style: TextStyle(
                      fontFamily: 'Ubuntu',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : labelColor),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(option,
                  style: TextStyle(
                      fontFamily: 'Ubuntu',
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: textColor)),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: Colors.blue, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -4))
        ],
      ),
      child: Row(
        children: [
          // Previous
          Expanded(
            child: OutlinedButton.icon(
              onPressed:
                  _currentIndex > 0 ? () => _goTo(_currentIndex - 1) : null,
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
              label: const Text('Prev', style: TextStyle(fontFamily: 'Ubuntu')),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Question grid button
          OutlinedButton(
            onPressed: () => _showQuestionPanel(isDark),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Icon(Icons.grid_view_rounded, size: 20),
          ),
          const SizedBox(width: 8),
          // Next / Submit
          Expanded(
            child: _currentIndex < _questions.length - 1
                ? ElevatedButton.icon(
                    onPressed: () => _goTo(_currentIndex + 1),
                    icon: const Text('Next',
                        style: TextStyle(fontFamily: 'Ubuntu')),
                    label:
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  )
                : ElevatedButton(
                    onPressed: () => _submitTest(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Submit',
                        style: TextStyle(
                            fontFamily: 'Ubuntu', fontWeight: FontWeight.w700)),
                  ),
          ),
        ],
      ),
    );
  }

  void _showQuestionPanel(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E30) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Question Panel',
                      style: TextStyle(
                          fontFamily: 'Ubuntu',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: isDark ? Colors.white : Colors.black87)),
                  _buildLegend(isDark),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1),
                itemCount: _questions.length,
                itemBuilder: (_, i) {
                  final isAnswered = _answers.containsKey(i);
                  final isMarkedQ = _marked[i] ?? false;
                  final isCurrent = i == _currentIndex;

                  Color bg;
                  if (isCurrent)
                    bg = Colors.blue;
                  else if (isMarkedQ)
                    bg = Colors.orange;
                  else if (isAnswered)
                    bg = Colors.green;
                  else
                    bg =
                        isDark ? const Color(0xFF252538) : Colors.grey.shade200;

                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _goTo(i);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          color: bg, borderRadius: BorderRadius.circular(8)),
                      child: Center(
                        child: Text('${i + 1}',
                            style: TextStyle(
                                fontFamily: 'Ubuntu',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: (isAnswered || isMarkedQ || isCurrent)
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.white60
                                        : Colors.black54))),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _submitTest();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: Text(
                      'Submit Test (${_answers.length}/${_questions.length} answered)',
                      style: const TextStyle(
                          fontFamily: 'Ubuntu', fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(bool isDark) {
    return Row(
      children: [
        _legendDot(Colors.green, 'Done'),
        const SizedBox(width: 10),
        _legendDot(Colors.orange, 'Marked'),
        const SizedBox(width: 10),
        _legendDot(
            isDark ? const Color(0xFF252538) : Colors.grey.shade300, 'Skip'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontFamily: 'Ubuntu', fontSize: 11)),
      ],
    );
  }

  void _showExitConfirmation() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E30) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Exit Test?',
            style:
                TextStyle(fontFamily: 'Ubuntu', fontWeight: FontWeight.w700)),
        content: const Text('Your progress will be lost if you exit now.',
            style: TextStyle(fontFamily: 'Ubuntu')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Stay', style: TextStyle(fontFamily: 'Ubuntu'))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Exit', style: TextStyle(fontFamily: 'Ubuntu')),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  MockTestResultScreen — detailed results + review
// ═══════════════════════════════════════════════════════
class MockTestResultScreen extends StatefulWidget {
  final Map<String, dynamic> testData;
  final List<Map<String, dynamic>> questions;
  final Map<int, int> answers;
  final Map<String, dynamic> results;

  const MockTestResultScreen({
    super.key,
    required this.testData,
    required this.questions,
    required this.answers,
    required this.results,
  });

  @override
  State<MockTestResultScreen> createState() => _MockTestResultScreenState();
}

class _MockTestResultScreenState extends State<MockTestResultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final passed = widget.results['passed'] as bool;
    final pct = double.tryParse(widget.results['percentage'].toString()) ?? 0;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: passed ? Colors.green : Colors.red,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.home_rounded),
          onPressed: () =>
              Navigator.popUntil(context, (route) => route.isFirst),
        ),
        title: Text(passed ? '🎉 Test Passed!' : '📚 Keep Practising',
            style: const TextStyle(
                fontFamily: 'Ubuntu', fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(
              fontFamily: 'Ubuntu', fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Results'),
            Tab(text: 'Review Answers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildResultsTab(isDark, passed, pct),
          _buildReviewTab(isDark),
        ],
      ),
    );
  }

  Widget _buildResultsTab(bool isDark, bool passed, double pct) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Score circle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E30) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color:
                        (passed ? Colors.green : Colors.red).withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 5)
              ],
            ),
            child: Column(
              children: [
                Text(
                  '${widget.results['score']}',
                  style: TextStyle(
                      fontFamily: 'Ubuntu',
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: passed ? Colors.green : Colors.red),
                ),
                Text('out of ${widget.results['total']! * 2}',
                    style: TextStyle(
                        fontFamily: 'Ubuntu',
                        fontSize: 14,
                        color: isDark ? Colors.white60 : Colors.grey)),
                Text('${widget.results['percentage']}%',
                    style: TextStyle(
                        fontFamily: 'Ubuntu',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: passed ? Colors.green : Colors.red)),
              ],
            ),
          ),

          // Stats row
          Row(
            children: [
              _statCard('✅ Correct', '${widget.results['correct']}',
                  Colors.green, isDark),
              const SizedBox(width: 10),
              _statCard(
                  '❌ Wrong', '${widget.results['wrong']}', Colors.red, isDark),
              const SizedBox(width: 10),
              _statCard('⏭️ Skipped', '${widget.results['skipped']}',
                  Colors.grey, isDark),
            ],
          ),
          const SizedBox(height: 16),

          // Performance bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E30) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Performance',
                    style: TextStyle(
                        fontFamily: 'Ubuntu',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 14,
                    backgroundColor:
                        isDark ? const Color(0xFF252538) : Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(
                        pct >= 60 ? Colors.green : Colors.red),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0%',
                        style: TextStyle(
                            fontFamily: 'Ubuntu',
                            fontSize: 12,
                            color: isDark ? Colors.white38 : Colors.grey)),
                    Text('Passing: ${widget.testData['passingMarks']} marks',
                        style: const TextStyle(
                            fontFamily: 'Ubuntu',
                            fontSize: 12,
                            color: Colors.orange)),
                    Text('100%',
                        style: TextStyle(
                            fontFamily: 'Ubuntu',
                            fontSize: 12,
                            color: isDark ? Colors.white38 : Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Retake button
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
    );
  }

  Widget _statCard(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
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
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: color)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Ubuntu',
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewTab(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.questions.length,
      itemBuilder: (_, i) {
        final q = widget.questions[i];
        final options = List<String>.from(q['options'] ?? []);
        final correctAns = q['answer'] as int? ?? 0;
        final userAns = widget.answers[i];
        final isCorrect = userAns == correctAns;
        final isSkipped = !widget.answers.containsKey(i);

        Color headerColor;
        if (isSkipped)
          headerColor = Colors.grey;
        else if (isCorrect)
          headerColor = Colors.green;
        else
          headerColor = Colors.red;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E30) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: headerColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: headerColor.withOpacity(0.1),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
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
                    Text(q['q'] ?? q['question'] ?? '',
                        style: TextStyle(
                            fontFamily: 'Ubuntu',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 12),

                    // Options
                    ...options.asMap().entries.map((e) {
                      final isCorrectOpt = e.key == correctAns;
                      final isUserOpt = e.key == userAns;
                      Color optColor = isDark
                          ? const Color(0xFF252538)
                          : Colors.grey.shade100;
                      Color textColor =
                          isDark ? Colors.white70 : Colors.black54;

                      if (isCorrectOpt) {
                        optColor = Colors.green.withOpacity(0.15);
                        textColor = Colors.green;
                      } else if (isUserOpt && !isCorrectOpt) {
                        optColor = Colors.red.withOpacity(0.15);
                        textColor = Colors.red;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: optColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text('${String.fromCharCode(65 + e.key)}. ',
                                style: TextStyle(
                                    fontFamily: 'Ubuntu',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: textColor)),
                            Expanded(
                              child: Text(e.value,
                                  style: TextStyle(
                                      fontFamily: 'Ubuntu',
                                      fontSize: 13,
                                      color: textColor)),
                            ),
                            if (isCorrectOpt)
                              const Icon(Icons.check_circle_rounded,
                                  color: Colors.green, size: 16),
                            if (isUserOpt && !isCorrectOpt)
                              const Icon(Icons.cancel_rounded,
                                  color: Colors.red, size: 16),
                          ],
                        ),
                      );
                    }),

                    // Explanation
                    if (q['explanation'] != null) ...[
                      const SizedBox(height: 10),
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
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
