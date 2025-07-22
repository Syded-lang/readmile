import 'package:flutter/material.dart';
import 'package:epubx/epubx.dart';
import 'package:readmile/models/book.dart';
import 'package:readmile/services/epub_service.dart';
import 'dart:io';

class EpubReaderScreen extends StatefulWidget {
  final Book book;

  const EpubReaderScreen({super.key, required this.book});

  @override
  State<EpubReaderScreen> createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends State<EpubReaderScreen> {
  EpubBook? _epubBook;
  bool _isLoading = true;
  bool _hasError = false;
  String? _tempFilePath;
  String _errorMessage = '';
  final EpubService _epubService = EpubService();

  // Reading state
  int _currentChapterIndex = 0;
  List<EpubChapter> _chapters = [];
  PageController _pageController = PageController();

  // Reading preferences
  double _fontSize = 16.0;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadEpub();
  }

  Future<void> _loadEpub() async {
    try {
      print('🔄 Starting EPUB load with epubx for: ${widget.book.title}');
      print('📁 GridFS EPUB ID: ${widget.book.gridfsEpubId}');

      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });

      // Download EPUB from GridFS
      final filePath = await _epubService.downloadEpubToTemp(
        widget.book.gridfsEpubId,
        widget.book.epubFilename,
      );

      print('📂 Downloaded to: $filePath');

      if (filePath != null && mounted) {
        _tempFilePath = filePath;

        // Read EPUB using epubx
        final file = File(filePath);
        final bytes = await file.readAsBytes();

        // Parse EPUB book
        _epubBook = await EpubReader.readBook(bytes);

        // Extract chapters for navigation
        _chapters = _flattenChapters(_epubBook!.Chapters ?? []);

        print('✅ EPUB loaded successfully');
        print('📖 Title: ${_epubBook!.Title}');
        print('👤 Author: ${_epubBook!.Author}');
        print('📄 Chapters: ${_chapters.length}');

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        print('❌ Failed to download EPUB file');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = 'Failed to download the book. Please check your internet connection.';
          });
        }
      }
    } catch (e) {
      print('❌ EPUB loading error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Error parsing EPUB: ${e.toString()}';
        });
      }
    }
  }

  List<EpubChapter> _flattenChapters(List<EpubChapter> chapters) {
    List<EpubChapter> flattened = [];
    for (var chapter in chapters) {
      flattened.add(chapter);
      if (chapter.SubChapters != null) {
        flattened.addAll(_flattenChapters(chapter.SubChapters!));
      }
    }
    return flattened;
  }

  @override
  void dispose() {
    if (_tempFilePath != null) {
      _epubService.deleteTemp(_tempFilePath!);
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(
          _epubBook?.Title ?? widget.book.title,
          style: const TextStyle(color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color(0xFF730000),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isLoading && !_hasError) ...[
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: _showChapterList,
              tooltip: 'Chapters',
            ),
            IconButton(
              icon: const Icon(Icons.text_format),
              onPressed: _showTextSettings,
              tooltip: 'Settings',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: _handleMenuSelection,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'info',
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Color(0xFF730000)),
                      SizedBox(width: 8),
                      Text('Book Info'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'bookmark',
                  child: Row(
                    children: [
                      Icon(Icons.bookmark, color: Color(0xFF730000)),
                      SizedBox(width: 8),
                      Text('Add Bookmark'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: (!_isLoading && !_hasError && _chapters.isNotEmpty)
          ? _buildNavigationBar()
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_chapters.isEmpty) {
      return _buildEmptyState();
    }

    return PageView.builder(
      controller: _pageController,
      itemCount: _chapters.length,
      onPageChanged: (index) {
        setState(() {
          _currentChapterIndex = index;
        });
        _saveReadingProgress();
      },
      itemBuilder: (context, index) {
        return _buildChapterView(_chapters[index]);
      },
    );
  }

  Widget _buildChapterView(EpubChapter chapter) {
    return Container(
      color: _isDarkMode ? Colors.black : Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chapter title
            if (chapter.Title?.isNotEmpty == true) ...[
              Text(
                chapter.Title!,
                style: TextStyle(
                  fontSize: _fontSize + 8,
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.white : const Color(0xFF730000),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Chapter content
            Text(
              _stripHtmlTags(chapter.HtmlContent ?? ''),
              style: TextStyle(
                fontSize: _fontSize,
                height: 1.6,
                color: _isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),

            const SizedBox(height: 40), // Extra space at the end
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF730000)),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading "${widget.book.title}"...',
              style: const TextStyle(
                color: Color(0xFF730000),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Downloading from your library',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Size: ${(widget.book.epubFileSizeBytes / 1024).round()}KB',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Color(0xFF730000),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to Load Book',
              style: TextStyle(
                color: Color(0xFF730000),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage.isNotEmpty
                  ? _errorMessage
                  : 'There was a problem loading "${widget.book.title}". Please try again.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Go Back',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: _loadEpub,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF730000),
                  ),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.book_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Content Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This book appears to be empty or corrupted.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF730000),
              ),
              child: const Text(
                'Go Back',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF730000),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _currentChapterIndex > 0 ? _previousChapter : null,
            icon: Icon(
              Icons.arrow_back,
              color: _currentChapterIndex > 0 ? Colors.white : Colors.white30,
            ),
            tooltip: 'Previous Chapter',
          ),

          Expanded(
            child: GestureDetector(
              onTap: _showChapterList,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '${_currentChapterIndex + 1} of ${_chapters.length}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

          IconButton(
            onPressed: _currentChapterIndex < _chapters.length - 1 ? _nextChapter : null,
            icon: Icon(
              Icons.arrow_forward,
              color: _currentChapterIndex < _chapters.length - 1 ? Colors.white : Colors.white30,
            ),
            tooltip: 'Next Chapter',
          ),
        ],
      ),
    );
  }

  String _stripHtmlTags(String htmlString) {
    // Remove HTML tags
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    String result = htmlString.replaceAll(exp, '');

    // Replace common HTML entities
    result = result
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('\n\n\n', '\n\n'); // Reduce excessive line breaks

    return result.trim();
  }

  void _previousChapter() {
    if (_currentChapterIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextChapter() {
    if (_currentChapterIndex < _chapters.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showChapterList() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chapters',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF730000),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _chapters.length,
                  itemBuilder: (context, index) {
                    final chapter = _chapters[index];
                    final isCurrentChapter = index == _currentChapterIndex;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isCurrentChapter
                            ? const Color(0xFF730000)
                            : Colors.grey[300],
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isCurrentChapter ? Colors.white : Colors.black,
                            fontWeight: isCurrentChapter ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      title: Text(
                        chapter.Title?.isNotEmpty == true
                            ? chapter.Title!
                            : 'Chapter ${index + 1}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: isCurrentChapter ? FontWeight.bold : FontWeight.normal,
                          color: isCurrentChapter ? const Color(0xFF730000) : null,
                        ),
                      ),
                      trailing: isCurrentChapter
                          ? const Icon(Icons.play_arrow, color: Color(0xFF730000))
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTextSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reading Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF730000),
              ),
            ),
            const SizedBox(height: 24),

            // Font Size
            Text('Font Size: ${_fontSize.round()}'),
            Slider(
              value: _fontSize,
              min: 12,
              max: 24,
              divisions: 6,
              activeColor: const Color(0xFF730000),
              onChanged: (value) {
                setState(() {
                  _fontSize = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Dark Mode Toggle
            SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Easier reading in low light'),
              value: _isDarkMode,
              activeColor: const Color(0xFF730000),
              onChanged: (value) {
                setState(() {
                  _isDarkMode = value;
                });
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'info':
        _showBookInfo();
        break;
      case 'bookmark':
        _addBookmark();
        break;
    }
  }

  void _showBookInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Book Information',
          style: TextStyle(color: Color(0xFF730000)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Title', _epubBook?.Title ?? widget.book.title),
            _buildInfoRow('Author', _epubBook?.Author ?? widget.book.author),
            _buildInfoRow('File Size', '${(widget.book.epubFileSizeBytes / 1024).round()}KB'),
            _buildInfoRow('Format', 'EPUB'),
            _buildInfoRow('Chapters', '${_chapters.length}'),
            _buildInfoRow('Current Chapter', '${_currentChapterIndex + 1}'),
            if (_chapters.isNotEmpty && _chapters[_currentChapterIndex].Title?.isNotEmpty == true)
              _buildInfoRow('Chapter Title', _chapters[_currentChapterIndex].Title!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF730000)),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _addBookmark() {
    // TODO: Implement bookmark functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bookmarked Chapter ${_currentChapterIndex + 1}'),
        backgroundColor: const Color(0xFF730000),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Remove bookmark
          },
        ),
      ),
    );
  }

  void _saveReadingProgress() {
    // TODO: Save reading progress to local storage or MongoDB
    print('📖 Progress: Chapter ${_currentChapterIndex + 1}/${_chapters.length}');
  }
}
