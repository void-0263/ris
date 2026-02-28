import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class CurrentAffairsScreen extends StatefulWidget {
  const CurrentAffairsScreen({super.key});

  @override
  State<CurrentAffairsScreen> createState() => _CurrentAffairsScreenState();
}

class _CurrentAffairsScreenState extends State<CurrentAffairsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'All';

  String get _dateString {
    return DateFormat('yyyy-MM-dd').format(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        title: const Text('Current Affairs',
            style:
                TextStyle(fontFamily: 'Ubuntu', fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
            tooltip: 'Select Date',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateHeader(),
          _buildCategoryTabs(isDark),
          Expanded(child: _buildArticlesList(isDark)),
        ],
      ),
    );
  }

  Widget _buildDateHeader() {
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final isYesterday = _isSameDay(
      _selectedDate,
      DateTime.now().subtract(const Duration(days: 1)),
    );

    String displayDate;
    if (isToday) {
      displayDate = 'Today';
    } else if (isYesterday) {
      displayDate = 'Yesterday';
    } else {
      displayDate = DateFormat('MMMM dd, yyyy').format(_selectedDate);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF2196F3),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
            },
          ),
          Expanded(
            child: Center(
              child: Text(
                displayDate,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Ubuntu',
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: isToday ? Colors.white30 : Colors.white,
            ),
            onPressed: isToday
                ? null
                : () {
                    setState(() {
                      _selectedDate =
                          _selectedDate.add(const Duration(days: 1));
                    });
                  },
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ✅ FIXED: Dark theme support for category tabs
  Widget _buildCategoryTabs(bool isDark) {
    final categories = ['All', 'National', 'Government', 'General'];

    return Container(
      height: 50,
      color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              selectedColor: const Color(0xFF2196F3),
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

  Widget _buildArticlesList(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('currentAffairs')
          .doc(_dateString)
          .collection('articles')
          .orderBy('publishedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString(), isDark);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2196F3)),
          );
        }

        var articles = snapshot.data?.docs ?? [];

        if (_selectedCategory != 'All') {
          articles = articles.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final category = (data['category'] ?? '').toString().toLowerCase();
            final selected = _selectedCategory.toLowerCase();
            return category == selected;
          }).toList();
        }

        if (articles.isEmpty) {
          return _buildEmptyState(isDark);
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index].data() as Map<String, dynamic>;
              return _buildArticleCard(article, isDark);
            },
          ),
        );
      },
    );
  }

  // ✅ FIXED: Dark theme support for article cards
  Widget _buildArticleCard(Map<String, dynamic> article, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: isDark ? const Color(0xFF1E1E30) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showArticleDetail(article),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(article['category']),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      article['category'] ?? 'General',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Ubuntu',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      article['source'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                        fontFamily: 'Ubuntu',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: 14, color: isDark ? Colors.white30 : Colors.grey),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                article['title'] ?? '',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Ubuntu',
                  height: 1.3,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (article['summary'] != null &&
                  article['summary'].toString().isNotEmpty)
                Text(
                  article['summary'],
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white60 : Colors.grey[700],
                    fontFamily: 'Ubuntu',
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 14,
                      color: isDark ? Colors.white38 : Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(article['publishedAt']),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.grey[600],
                      fontFamily: 'Ubuntu',
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

  // ✅ FIXED: Dark theme support for article detail modal
  void _showArticleDetail(Map<String, dynamic> article) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E30) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(article['category']),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          article['category'] ?? 'General',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Ubuntu',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      article['title'] ?? '',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Ubuntu',
                        height: 1.3,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          article['source'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2196F3),
                            fontFamily: 'Ubuntu',
                          ),
                        ),
                        Text(' • ',
                            style: TextStyle(
                                color: isDark
                                    ? Colors.white24
                                    : Colors.grey[400])),
                        Text(
                          _formatTime(article['publishedAt']),
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                            fontFamily: 'Ubuntu',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (article['summary'] != null &&
                        article['summary'].toString().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF252538)
                              : Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          article['summary'],
                          style: TextStyle(
                            fontSize: 15,
                            fontFamily: 'Ubuntu',
                            height: 1.5,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (article['content'] != null &&
                        article['content'].toString().isNotEmpty)
                      Text(
                        _cleanContent(article['content']),
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: 'Ubuntu',
                          height: 1.6,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    const SizedBox(height: 24),
                    if (article['url'] != null &&
                        article['url'].toString().isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: () async {
                          final success = await _launchURL(article['url']);
                          if (!success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Could not open article',
                                    style: TextStyle(fontFamily: 'Ubuntu')),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Read Full Article',
                            style: TextStyle(fontFamily: 'Ubuntu')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final isToday = _isSameDay(_selectedDate, DateTime.now());

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined,
              size: 80, color: isDark ? Colors.white24 : Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _selectedCategory == 'All'
                ? (isToday
                    ? 'No articles yet today'
                    : 'No articles for ${DateFormat('MMM dd, yyyy').format(_selectedDate)}')
                : 'No $_selectedCategory articles',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white60 : Colors.grey[600],
              fontFamily: 'Ubuntu',
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedCategory != 'All')
            ElevatedButton(
              onPressed: () => setState(() => _selectedCategory = 'All'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
              ),
              child: const Text('Show All',
                  style: TextStyle(fontFamily: 'Ubuntu')),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading articles',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: 'Ubuntu')),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white60 : Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() {}),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
              ),
              child:
                  const Text('Retry', style: TextStyle(fontFamily: 'Ubuntu')),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'national':
        return Colors.blue;
      case 'government':
        return Colors.green;
      case 'general':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final date = (timestamp as Timestamp).toDate();
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else {
        return DateFormat('MMM dd, yyyy').format(date);
      }
    } catch (e) {
      return '';
    }
  }

  String _cleanContent(String content) {
    return content
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }

  Future<bool> _launchURL(String? url) async {
    if (url == null || url.isEmpty) return false;
    try {
      String cleanUrl = url.trim();
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }
      final uri = Uri.parse(cleanUrl);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error launching URL: $e');
      return false;
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }
}
