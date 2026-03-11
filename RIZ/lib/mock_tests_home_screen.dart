import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'mock_test_screen.dart';

// ════════════════════════════════════════════════════
//  MockTestsHomeScreen — Browse and filter mock tests

class MockTestsHomeScreen extends StatefulWidget {
  const MockTestsHomeScreen({super.key});

  @override
  State<MockTestsHomeScreen> createState() => _MockTestsHomeScreenState();
}

class _MockTestsHomeScreenState extends State<MockTestsHomeScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String _selectedExam = 'All';

  final List<String> _exams = [
    'All',
    'TNPSC',
    'UPSC',
    'SSC',
    'Banking',
    'Railways',
    'Defence'
  ];

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
        title: const Text('Mock Tests',
            style:
                TextStyle(fontFamily: 'Ubuntu', fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _navigateToHistory(),
            tooltip: 'Test History',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildExamFilter(isDark),
          Expanded(child: _buildMockTestsList(isDark)),
        ],
      ),
    );
  }

  Widget _buildExamFilter(bool isDark) {
    return Container(
      height: 60,
      color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: _exams.length,
        itemBuilder: (context, index) {
          final exam = _exams[index];
          final isSelected = _selectedExam == exam;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(exam),
              selected: isSelected,
              onSelected: (selected) => setState(() => _selectedExam = exam),
              selectedColor: Colors.blue,
              backgroundColor:
                  isDark ? const Color(0xFF252538) : Colors.grey[200],
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: FontWeight.w600,
                fontFamily: 'Ubuntu',
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMockTestsList(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredTests(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.blue));
        }

        final tests = snapshot.data?.docs ?? [];

        if (tests.isEmpty) {
          return _buildEmptyState(isDark);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tests.length,
          itemBuilder: (context, index) {
            final test = tests[index].data() as Map<String, dynamic>;
            final testId = tests[index].id;
            return _buildMockTestCard(test, testId, isDark);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getFilteredTests() {
    Query query =
        _db.collection('mockTests').where('isActive', isEqualTo: true);

    if (_selectedExam != 'All') {
      query = query.where('exam', isEqualTo: _selectedExam);
    }

    return query.orderBy('createdAt', descending: true).snapshots();
  }

  Widget _buildMockTestCard(
      Map<String, dynamic> test, String testId, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      color: isDark ? const Color(0xFF1E1E30) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _startTest(testId, test),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _getExamColor(test['exam']),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      test['exam'] ?? 'General',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Ubuntu',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(test['difficulty']),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      test['difficulty'] ?? 'Medium',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Ubuntu',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                test['title'] ?? '',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Ubuntu',
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              if (test['description'] != null)
                Text(
                  test['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white60 : Colors.grey[700],
                    fontFamily: 'Ubuntu',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoChip(
                      Icons.quiz, '${test['totalQuestions'] ?? 0} Qs', isDark),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                      Icons.timer, '${test['duration'] ?? 0} min', isDark),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                      Icons.star, '${test['totalMarks'] ?? 0} marks', isDark),
                ],
              ),
              if (test['negativeMarking'] == true) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.warning_amber,
                        size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Negative marking: -${test['negativeMarkingRatio'] ?? 0.33}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                        fontFamily: 'Ubuntu',
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _startTest(testId, test),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Start Test',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Ubuntu',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252538) : Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 16, color: isDark ? Colors.white70 : Colors.blue[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.blue[700],
              fontFamily: 'Ubuntu',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined,
              size: 80, color: isDark ? Colors.white24 : Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No mock tests available',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white60 : Colors.grey[600],
              fontFamily: 'Ubuntu',
            ),
          ),
        ],
      ),
    );
  }

  Color _getExamColor(String? exam) {
    switch (exam?.toUpperCase()) {
      case 'TNPSC':
        return const Color(0xFF8B4513);
      case 'UPSC':
        return Colors.blue[700]!;
      case 'SSC':
        return Colors.purple[700]!;
      case 'BANKING':
        return Colors.green[700]!;
      case 'RAILWAYS':
        return Colors.red[700]!;
      case 'DEFENCE':
        return Colors.orange[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  Color _getDifficultyColor(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  void _startTest(String testId, Map<String, dynamic> test) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MockTestScreen(testId: testId, testData: test),
      ),
    );
  }

  void _navigateToHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test history feature coming soon!')),
    );
  }
}
