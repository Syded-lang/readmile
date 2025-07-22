import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/book.dart';
import '../../providers/reading_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/epub_service.dart';

class EpubReaderScreen extends StatefulWidget {
  final Book book;
  final String? filePath;

  const EpubReaderScreen({
    Key? key,
    required this.book,
    this.filePath,
  }) : super(key: key);

  @override
  State<EpubReaderScreen> createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends State<EpubReaderScreen> {
  bool isLoading = true;
  List<String> _chapters = [];
  int _currentIndex = 0;
  String _currentContent = '';
  bool _showControls = true;
  DateTime _startReadingTime = DateTime.now();

  // FIXED: Store provider references to avoid accessing them after disposal
  ReadingProvider? _readingProvider;
  SettingsProvider? _settingsProvider;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // FIXED: Store provider references safely during active widget lifecycle
    _readingProvider = Provider.of<ReadingProvider>(context, listen: false);
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
  }

  @override
  void dispose() {
    // FIXED: Use stored provider reference instead of Provider.of(context)
    _updateReadingTimeOnDispose();
    super.dispose();
  }

  void _updateReadingTimeOnDispose() {
    try {
      // FIXED: Only update if providers are still available
      if (_readingProvider != null) {
        final now = DateTime.now();
        final readingSeconds = now.difference(_startReadingTime).inSeconds;
        if (readingSeconds > 3) {
          _readingProvider!.updateReadingTime(widget.book.id, readingSeconds);
        }
      }
    } catch (e) {
      print('⚠️ Error updating reading time on dispose: $e');
    }
  }

  Future<void> _loadBook() async {
    try {
      final epubService = EpubService();
      if (widget.filePath != null) {
        _chapters = await epubService.getOfflineChapters(widget.filePath!);
      } else {
        _chapters = await epubService.getOnlineChapters(widget.book.id);
      }

      // FIXED: Use stored provider reference
      if (_readingProvider != null) {
        final progress = _readingProvider!.getProgressForBook(widget.book.id);
        if (progress != null && progress.chapterIndex < _chapters.length) {
          _currentIndex = progress.chapterIndex;
        }
      }

      await _loadChapter(_currentIndex);
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          _currentContent = 'Error loading book: $e';
        });
      }
    }
  }

  Future<void> _loadChapter(int index) async {
    if (index < 0 || index >= _chapters.length) return;

    // Update reading time before loading new chapter
    _updateReadingTime();

    try {
      final epubService = EpubService();
      String content;
      if (widget.filePath != null) {
        content = await epubService.getOfflineChapterContent(widget.filePath!, index);
      } else {
        content = await epubService.getOnlineChapterContent(widget.book.id, index);
      }

      if (mounted) {
        setState(() {
          _currentIndex = index;
          _currentContent = content;
          _startReadingTime = DateTime.now();
        });

        // FIXED: Use stored provider reference and check if mounted
        if (_readingProvider != null) {
          final progressPercentage = _chapters.isNotEmpty
              ? ((_currentIndex + 1) / _chapters.length) * 100
              : 0.0;
          await _readingProvider!.updateReadingProgress(
            widget.book.id,
            _currentIndex,
            progressPercentage,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentContent = 'Error loading chapter: $e';
        });
      }
    }
  }

  void _updateReadingTime() {
    try {
      // FIXED: Use stored provider reference
      if (_readingProvider != null) {
        final now = DateTime.now();
        final readingSeconds = now.difference(_startReadingTime).inSeconds;
        if (readingSeconds > 3) {
          _readingProvider!.updateReadingTime(widget.book.id, readingSeconds);
          _startReadingTime = now;
        }
      }
    } catch (e) {
      print('⚠️ Error updating reading time: $e');
    }
  }

  void _toggleControls() {
    if (mounted) {
      setState(() {
        _showControls = !_showControls;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return Scaffold(
          appBar: _showControls ? _buildAppBar(settingsProvider) : null,
          body: isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF730000)))
              : _buildReaderContent(settingsProvider),
          bottomNavigationBar: _showControls ? _buildBottomBar(settingsProvider) : null,
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(SettingsProvider settingsProvider) {
    return AppBar(
      title: Text(
        widget.book.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      backgroundColor: settingsProvider.theme == 'dark'
          ? const Color(0xFF1E1E1E)
          : const Color(0xFF730000),
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.text_fields),
          tooltip: 'Reading Settings',
          onPressed: () async {
            _updateReadingTime();
            await Navigator.pushNamed(context, '/settings');
            _startReadingTime = DateTime.now();
          },
        ),
        Consumer<ReadingProvider>(
          builder: (context, readingProvider, child) {
            final isBookmarked = readingProvider.isBookmarked(widget.book.id, _currentIndex);
            return IconButton(
              icon: Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: isBookmarked ? const Color(0xFFC5A880) : Colors.white,
              ),
              onPressed: () {
                _updateReadingTime();
                readingProvider.toggleBookmark(widget.book.id, _currentIndex);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          isBookmarked ? 'Bookmark removed' : 'Bookmark added'
                      ),
                      duration: const Duration(seconds: 1),
                      backgroundColor: const Color(0xFF730000),
                    ),
                  );
                }
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildReaderContent(SettingsProvider settingsProvider) {
    return GestureDetector(
      onTap: _toggleControls,
      child: Container(
        color: settingsProvider.backgroundColor,
        padding: EdgeInsets.all(settingsProvider.margin),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_chapters.isNotEmpty && _currentIndex < _chapters.length)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      _chapters[_currentIndex],
                      style: TextStyle(
                        fontFamily: settingsProvider.fontFamily,
                        fontSize: settingsProvider.fontSize + 4,
                        fontWeight: FontWeight.bold,
                        color: settingsProvider.textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Text(
                  _currentContent,
                  style: TextStyle(
                    fontFamily: settingsProvider.fontFamily,
                    fontSize: settingsProvider.fontSize,
                    height: settingsProvider.lineHeight,
                    color: settingsProvider.textColor,
                  ),
                  textAlign: settingsProvider.textAlign,
                ),
                // Add some bottom padding to prevent content from being cut off
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(SettingsProvider settingsProvider) {
    return BottomAppBar(
      color: settingsProvider.theme == 'dark'
          ? const Color(0xFF1E1E1E)
          : Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Previous chapter button
            IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: settingsProvider.theme == 'dark'
                    ? const Color(0xFFE0E0E0)
                    : const Color(0xFF730000),
              ),
              onPressed: _currentIndex > 0
                  ? () => _loadChapter(_currentIndex - 1)
                  : null,
              tooltip: 'Previous Chapter',
            ),

            // Chapter progress
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_currentIndex + 1} of ${_chapters.length}',
                    style: TextStyle(
                      color: settingsProvider.theme == 'dark'
                          ? const Color(0xFFE0E0E0)
                          : const Color(0xFF730000),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_chapters.isNotEmpty)
                    LinearProgressIndicator(
                      value: (_currentIndex + 1) / _chapters.length,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation(
                        settingsProvider.theme == 'dark'
                            ? const Color(0xFFC5A880)
                            : const Color(0xFF730000),
                      ),
                    ),
                ],
              ),
            ),

            // Next chapter button
            IconButton(
              icon: Icon(
                Icons.arrow_forward_ios,
                color: settingsProvider.theme == 'dark'
                    ? const Color(0xFFE0E0E0)
                    : const Color(0xFF730000),
              ),
              onPressed: _currentIndex < _chapters.length - 1
                  ? () => _loadChapter(_currentIndex + 1)
                  : null,
              tooltip: 'Next Chapter',
            ),
          ],
        ),
      ),
    );
  }
}
