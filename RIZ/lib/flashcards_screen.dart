import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

// ════════════════════════════════════
//  DigitalFlashcardsScreen — Browse + Review
// ═══════════════════════════════════════════════════════
class DigitalFlashcardsScreen extends StatefulWidget {
  const DigitalFlashcardsScreen({super.key});

  @override
  State<DigitalFlashcardsScreen> createState() =>
      _DigitalFlashcardsScreenState();
}

class _DigitalFlashcardsScreenState extends State<DigitalFlashcardsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String _selectedCategory = 'All';
  String _selectedDifficulty = 'All';

  final List<String> _difficulties = ['All', 'easy', 'medium', 'hard'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        title: const Text('Digital Flashcards',
            style:
                TextStyle(fontFamily: 'Ubuntu', fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _showFilterSheet(isDark),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(isDark),
          _buildStats(isDark),
          Expanded(child: _buildCardsList(isDark)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startReview(isDark),
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Start Review',
            style:
                TextStyle(fontFamily: 'Ubuntu', fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildCategoryFilter(bool isDark) {
    return Container(
      height: 56,
      color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      child: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('flashcards').snapshots(),
        builder: (context, snapshot) {
          final categories = ['All'];
          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              final cat = (doc.data() as Map)['category']?.toString();
              if (cat != null && !categories.contains(cat)) categories.add(cat);
            }
          }
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            itemCount: categories.length,
            itemBuilder: (_, i) {
              final cat = categories[i];
              final sel = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: sel,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                  selectedColor: Colors.purple,
                  backgroundColor:
                      isDark ? const Color(0xFF252538) : Colors.grey[200],
                  labelStyle: TextStyle(
                    fontFamily: 'Ubuntu',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: sel
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStats(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('flashcards').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 4);
        final total = snapshot.data!.docs.length;
        final easy = snapshot.data!.docs
            .where((d) => (d.data() as Map)['difficulty'] == 'easy')
            .length;
        final hard = snapshot.data!.docs
            .where((d) => (d.data() as Map)['difficulty'] == 'hard')
            .length;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          child: Row(
            children: [
              _statChip('$total Total', Colors.purple, isDark),
              const SizedBox(width: 8),
              _statChip('$easy Easy', Colors.green, isDark),
              const SizedBox(width: 8),
              _statChip('$hard Hard', Colors.red, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _statChip(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontFamily: 'Ubuntu',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }

  Widget _buildCardsList(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredCards(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(fontFamily: 'Ubuntu')));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.purple));
        }

        final cards = snapshot.data?.docs ?? [];
        if (cards.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.style_rounded,
                    size: 80,
                    color: isDark ? Colors.white24 : Colors.grey[300]),
                const SizedBox(height: 16),
                Text('No flashcards found',
                    style: TextStyle(
                        fontFamily: 'Ubuntu',
                        fontSize: 16,
                        color: isDark ? Colors.white60 : Colors.grey[600])),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() {
                    _selectedCategory = 'All';
                    _selectedDifficulty = 'All';
                  }),
                  child: const Text('Clear filters',
                      style: TextStyle(
                          fontFamily: 'Ubuntu', color: Colors.purple)),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: cards.length,
          itemBuilder: (_, i) {
            final card = cards[i].data() as Map<String, dynamic>;
            final cardId = cards[i].id;
            return _buildFlashcardTile(card, cardId, isDark);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getFilteredCards() {
    Query q = _db.collection('flashcards');
    if (_selectedCategory != 'All')
      q = q.where('category', isEqualTo: _selectedCategory);
    if (_selectedDifficulty != 'All')
      q = q.where('difficulty', isEqualTo: _selectedDifficulty);
    return q.limit(100).snapshots();
  }

  Widget _buildFlashcardTile(
      Map<String, dynamic> card, String cardId, bool isDark) {
    final difficulty = card['difficulty'] ?? 'easy';
    final Color diffColor = difficulty == 'easy'
        ? Colors.green
        : difficulty == 'hard'
            ? Colors.red
            : Colors.orange;

    final examTags = List<String>.from(card['examTags'] ?? []);

    return GestureDetector(
      onTap: () => _openFlashcard(card, isDark),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Column(
          children: [
            // Card header
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.purple[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(card['category'] ?? 'General',
                        style: TextStyle(
                            fontFamily: 'Ubuntu',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.purple[900])),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: diffColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(difficulty,
                        style: TextStyle(
                            fontFamily: 'Ubuntu',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: diffColor)),
                  ),
                  const Spacer(),
                  Icon(Icons.flip_rounded,
                      size: 16, color: isDark ? Colors.white38 : Colors.grey),
                ],
              ),
            ),

            // Front text
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(card['front'] ?? '',
                    style: TextStyle(
                        fontFamily: 'Ubuntu',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87)),
              ),
            ),

            // Divider + back peek
            Divider(
                height: 1,
                color: isDark ? const Color(0xFF2A2A40) : Colors.grey.shade100),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      size: 14, color: Colors.purple),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(card['back'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontFamily: 'Ubuntu',
                            fontSize: 13,
                            color: isDark ? Colors.white60 : Colors.grey[700])),
                  ),
                ],
              ),
            ),

            // Exam tags
            if (examTags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: Wrap(
                  spacing: 6,
                  children: examTags
                      .take(3)
                      .map((tag) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(tag,
                                style: const TextStyle(
                                    fontFamily: 'Ubuntu',
                                    fontSize: 10,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600)),
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openFlashcard(Map<String, dynamic> card, bool isDark) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardDetailScreen(card: card),
      ),
    );
  }

  void _showFilterSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E30) : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filter Flashcards',
                  style: TextStyle(
                      fontFamily: 'Ubuntu',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 16),
              Text('Difficulty',
                  style: TextStyle(
                      fontFamily: 'Ubuntu',
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black54)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _difficulties
                    .map((d) => ChoiceChip(
                          label: Text(d,
                              style: const TextStyle(fontFamily: 'Ubuntu')),
                          selected: _selectedDifficulty == d,
                          onSelected: (_) {
                            setModal(() => _selectedDifficulty = d);
                            setState(() => _selectedDifficulty = d);
                          },
                          selectedColor: Colors.purple,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Apply',
                      style: TextStyle(
                          fontFamily: 'Ubuntu', fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startReview(bool isDark) async {
    final snap = await _getFilteredCards().first;
    if (snap.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No flashcards to review',
                style: TextStyle(fontFamily: 'Ubuntu'))),
      );
      return;
    }

    final cards = snap.docs
        .map((d) => d.data() as Map<String, dynamic>)
        .toList()
      ..shuffle(Random());

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FlashcardReviewScreen(cards: cards),
        ),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════
//  FlashcardDetailScreen — single card flip view
// ═══════════════════════════════════════════════════════
class FlashcardDetailScreen extends StatefulWidget {
  final Map<String, dynamic> card;
  const FlashcardDetailScreen({super.key, required this.card});

  @override
  State<FlashcardDetailScreen> createState() => _FlashcardDetailScreenState();
}

class _FlashcardDetailScreenState extends State<FlashcardDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _animation = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    HapticFeedback.lightImpact();
    if (_isFlipped) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = widget.card;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        title: Text(card['category'] ?? 'Flashcard',
            style: const TextStyle(
                fontFamily: 'Ubuntu', fontWeight: FontWeight.w700)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Tap the card to reveal the answer',
                  style: TextStyle(
                      fontFamily: 'Ubuntu',
                      fontSize: 13,
                      color: isDark ? Colors.white38 : Colors.grey)),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _flip,
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (_, __) {
                    final angle = _animation.value * pi;
                    final showFront = angle < pi / 2;
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 280),
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: showFront
                                ? [const Color(0xFF7B1FA2), Colors.purple]
                                : [const Color(0xFF1565C0), Colors.blue],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                                color: (showFront ? Colors.purple : Colors.blue)
                                    .withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8))
                          ],
                        ),
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..rotateY(showFront ? 0 : pi),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                  showFront
                                      ? Icons.help_outline_rounded
                                      : Icons.lightbulb_rounded,
                                  color: Colors.white54,
                                  size: 36),
                              const SizedBox(height: 16),
                              Text(
                                showFront
                                    ? card['front'] ?? ''
                                    : card['back'] ?? '',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontFamily: 'Ubuntu',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.5),
                              ),
                              const SizedBox(height: 20),
                              Text(showFront ? 'QUESTION' : 'ANSWER',
                                  style: const TextStyle(
                                      fontFamily: 'Ubuntu',
                                      fontSize: 11,
                                      letterSpacing: 2,
                                      color: Colors.white54)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app_rounded,
                      color: isDark ? Colors.white38 : Colors.grey, size: 18),
                  const SizedBox(width: 6),
                  Text(_isFlipped ? 'Tap to see question' : 'Tap to see answer',
                      style: TextStyle(
                          fontFamily: 'Ubuntu',
                          fontSize: 13,
                          color: isDark ? Colors.white38 : Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  FlashcardReviewScreen — swipe to know / don't know
// ═══════════════════════════════════════════════════════
class FlashcardReviewScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cards;
  const FlashcardReviewScreen({super.key, required this.cards});

  @override
  State<FlashcardReviewScreen> createState() => _FlashcardReviewScreenState();
}

class _FlashcardReviewScreenState extends State<FlashcardReviewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnim;
  bool _isFlipped = false;
  int _currentIndex = 0;
  int _known = 0;
  int _unknown = 0;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _flipController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flip() {
    HapticFeedback.lightImpact();
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  void _respond(bool knew) {
    HapticFeedback.mediumImpact();
    setState(() {
      if (knew)
        _known++;
      else
        _unknown++;
      if (_currentIndex < widget.cards.length - 1) {
        _currentIndex++;
        _isFlipped = false;
        _flipController.reset();
      } else {
        _showCompletionScreen();
      }
    });
  }

  void _showCompletionScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = widget.cards.length;
    final pct = (_known / total * 100).round();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E30) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Session Complete! 🎉',
            style:
                TextStyle(fontFamily: 'Ubuntu', fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$pct% mastered',
                style: TextStyle(
                    fontFamily: 'Ubuntu',
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: pct >= 70 ? Colors.green : Colors.orange)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(children: [
                  Text('$_known',
                      style: const TextStyle(
                          fontFamily: 'Ubuntu',
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.green)),
                  const Text('I knew this',
                      style: TextStyle(fontFamily: 'Ubuntu', fontSize: 12)),
                ]),
                Column(children: [
                  Text('$_unknown',
                      style: const TextStyle(
                          fontFamily: 'Ubuntu',
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.red)),
                  const Text('Need practice',
                      style: TextStyle(fontFamily: 'Ubuntu', fontSize: 12)),
                ]),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done', style: TextStyle(fontFamily: 'Ubuntu')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentIndex = 0;
                _known = 0;
                _unknown = 0;
                _isFlipped = false;
                _flipController.reset();
                widget.cards.shuffle(Random());
              });
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Review Again',
                style: TextStyle(
                    fontFamily: 'Ubuntu', fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = widget.cards[_currentIndex];
    final progress = (_currentIndex + 1) / widget.cards.length;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Review Mode',
                style: TextStyle(
                    fontFamily: 'Ubuntu',
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            Text('${_currentIndex + 1} of ${widget.cards.length}',
                style: const TextStyle(fontFamily: 'Ubuntu', fontSize: 12)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            child: Row(
              children: [
                Text('$_known ✅',
                    style: const TextStyle(fontFamily: 'Ubuntu', fontSize: 13)),
                const SizedBox(width: 8),
                Text('$_unknown ❌',
                    style: const TextStyle(fontFamily: 'Ubuntu', fontSize: 13)),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.purple.shade300,
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Category + difficulty
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _badge(card['category'] ?? '', Colors.purple),
                        const SizedBox(width: 8),
                        _badge(
                            card['difficulty'] ?? '',
                            card['difficulty'] == 'easy'
                                ? Colors.green
                                : card['difficulty'] == 'hard'
                                    ? Colors.red
                                    : Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Flip card
                    GestureDetector(
                      onTap: _flip,
                      child: AnimatedBuilder(
                        animation: _flipAnim,
                        builder: (_, __) {
                          final angle = _flipAnim.value * pi;
                          final showFront = angle < pi / 2;
                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(angle),
                            child: Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(minHeight: 240),
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: showFront
                                      ? [
                                          const Color(0xFF6A1B9A),
                                          const Color(0xFF9C27B0)
                                        ]
                                      : [
                                          const Color(0xFF1565C0),
                                          const Color(0xFF2196F3)
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                      color: (showFront
                                              ? Colors.purple
                                              : Colors.blue)
                                          .withOpacity(0.35),
                                      blurRadius: 24,
                                      offset: const Offset(0, 10))
                                ],
                              ),
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..rotateY(showFront ? 0 : pi),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                        showFront
                                            ? Icons.help_outline_rounded
                                            : Icons.lightbulb_rounded,
                                        color: Colors.white54,
                                        size: 32),
                                    const SizedBox(height: 14),
                                    Text(
                                      showFront
                                          ? card['front'] ?? ''
                                          : card['back'] ?? '',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontFamily: 'Ubuntu',
                                          fontSize: 19,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          height: 1.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(showFront ? 'QUESTION' : 'ANSWER',
                                        style: const TextStyle(
                                            fontFamily: 'Ubuntu',
                                            fontSize: 10,
                                            letterSpacing: 2.5,
                                            color: Colors.white54)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),
                    Text(
                        _isFlipped
                            ? 'How well did you know this?'
                            : 'Tap card to reveal answer',
                        style: TextStyle(
                            fontFamily: 'Ubuntu',
                            fontSize: 13,
                            color: isDark ? Colors.white38 : Colors.grey)),
                  ],
                ),
              ),
            ),
          ),

          // Response buttons
          if (_isFlipped)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 10,
                      offset: const Offset(0, -4))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _respond(false),
                      icon: const Text('😕', style: TextStyle(fontSize: 18)),
                      label: const Text("Didn't know",
                          style: TextStyle(
                              fontFamily: 'Ubuntu',
                              fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          side: BorderSide(color: Colors.red.withOpacity(0.3)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _respond(true),
                      icon: const Text('😊', style: TextStyle(fontSize: 18)),
                      label: const Text('I knew it!',
                          style: TextStyle(
                              fontFamily: 'Ubuntu',
                              fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade50,
                          foregroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          side:
                              BorderSide(color: Colors.green.withOpacity(0.3)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Text(text,
          style: TextStyle(
              fontFamily: 'Ubuntu',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }
}
