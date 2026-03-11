import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

// ═════════════════════════════════════════════════════
//  StudyVaultScreen — Browse and filter study materials

class StudyVaultScreen extends StatefulWidget {
  const StudyVaultScreen({super.key});

  @override
  State<StudyVaultScreen> createState() => _StudyVaultScreenState();
}

class _StudyVaultScreenState extends State<StudyVaultScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String _selectedExam = 'All';
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _exams = [
    'All',
    'TNPSC',
    'UPSC',
    'SSC',
    'Banking',
    'Railways',
    'Defence'
  ];

  final List<String> _categories = [
    'All',
    'Syllabus',
    'Notes',
    'Videos',
    'PDFs',
    'Previous Papers',
    'Current Affairs'
  ];

  @override
  void dispose() {
    _searchController.dispose();
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
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        title: const Text('Study Vault',
            style:
                TextStyle(fontFamily: 'Ubuntu', fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () => _navigateToBookmarks(),
            tooltip: 'My Bookmarks',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(isDark),
          _buildExamFilter(isDark),
          _buildCategoryFilter(isDark),
          Expanded(child: _buildStudyLinksList(isDark)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: (value) =>
            setState(() => _searchQuery = value.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Search study materials...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: isDark ? const Color(0xFF252538) : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildExamFilter(bool isDark) {
    return Container(
      height: 50,
      color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
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
              selectedColor: Colors.orange,
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

  Widget _buildCategoryFilter(bool isDark) {
    return Container(
      height: 50,
      color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) =>
                  setState(() => _selectedCategory = category),
              selectedColor: Colors.orange[700],
              backgroundColor:
                  isDark ? const Color(0xFF252538) : Colors.grey[200],
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
                fontSize: 12,
                fontFamily: 'Ubuntu',
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudyLinksList(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredLinks(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.orange));
        }

        var links = snapshot.data?.docs ?? [];

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          links = links.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = (data['title'] ?? '').toString().toLowerCase();
            final description =
                (data['description'] ?? '').toString().toLowerCase();
            return title.contains(_searchQuery) ||
                description.contains(_searchQuery);
          }).toList();
        }

        if (links.isEmpty) {
          return _buildEmptyState(isDark);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: links.length,
          itemBuilder: (context, index) {
            final link = links[index].data() as Map<String, dynamic>;
            final linkId = links[index].id;
            return _buildStudyLinkCard(link, linkId, isDark);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getFilteredLinks() {
    Query query = _db.collection('studyLinks');

    if (_selectedExam != 'All') {
      query = query.where('exam', isEqualTo: _selectedExam);
    }

    if (_selectedCategory != 'All') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    return query.snapshots();
  }

  Widget _buildStudyLinkCard(
      Map<String, dynamic> link, String linkId, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: isDark ? const Color(0xFF1E1E30) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _launchURL(link['url']),
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
                      color: _getCategoryColor(link['category']),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      link['category'] ?? 'General',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Ubuntu',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      link['exam'] ?? 'General',
                      style: TextStyle(
                        color: Colors.orange[900],
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Ubuntu',
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.bookmark_border, size: 20),
                    onPressed: () => _bookmarkLink(linkId),
                    color: Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                link['title'] ?? '',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Ubuntu',
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              if (link['description'] != null &&
                  link['description'].toString().isNotEmpty)
                Text(
                  link['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white60 : Colors.grey[700],
                    fontFamily: 'Ubuntu',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(_getTypeIcon(link['type']),
                      size: 16,
                      color: isDark ? Colors.white38 : Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    link['type'] ?? 'Link',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.grey[600],
                      fontFamily: 'Ubuntu',
                    ),
                  ),
                  if (link['isOfficial'] == true) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.verified, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    const Text(
                      'Official',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontFamily: 'Ubuntu',
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open,
              size: 80, color: isDark ? Colors.white24 : Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No study materials found',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white60 : Colors.grey[600],
              fontFamily: 'Ubuntu',
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedExam = 'All';
                _selectedCategory = 'All';
                _searchController.clear();
                _searchQuery = '';
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear Filters',
                style: TextStyle(fontFamily: 'Ubuntu')),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'syllabus':
        return Colors.blue;
      case 'notes':
        return Colors.green;
      case 'videos':
        return Colors.red;
      case 'pdfs':
        return Colors.purple;
      case 'previous papers':
        return Colors.orange;
      case 'current affairs':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'video':
        return Icons.play_circle_outline;
      case 'website':
        return Icons.language;
      case 'article':
        return Icons.article;
      default:
        return Icons.link;
    }
  }

  Future<void> _launchURL(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      String cleanUrl = url.trim();
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }
      final uri = Uri.parse(cleanUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  Future<void> _bookmarkLink(String linkId) async {
    final userId = 'user123'; // Replace with actual user ID from Firebase Auth
    await _db
        .collection('userStudyLinkBookmarks')
        .doc(userId)
        .collection('bookmarks')
        .doc(linkId)
        .set({
      'bookmarkedAt': FieldValue.serverTimestamp(),
      'notes': '',
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to bookmarks!',
              style: TextStyle(fontFamily: 'Ubuntu')),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _navigateToBookmarks() {
    // TODO: Navigate to bookmarks screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bookmarks feature coming soon!')),
    );
  }
}
