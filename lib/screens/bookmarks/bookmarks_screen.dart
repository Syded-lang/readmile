import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:readmile/providers/reading_provider.dart';
import 'package:readmile/providers/offline_provider.dart';
import 'package:readmile/screens/offline/offline_books_screen.dart';
import 'package:readmile/screens/stats/reading_stats_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<Book> books;
  const HomeScreen({super.key, required this.books});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.menu_book, color: Color(0xFFC5A880)),
            SizedBox(width: 8),
            Text('ReadMile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
          ],
        ),
        backgroundColor: Color(0xFF730000),
        actions: [
          // Download count indicator
          Consumer<OfflineProvider>(
            builder: (context, offlineProvider, child) {
              final downloadCount = offlineProvider.offlineBooks.length;
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.download, color: Colors.white),
                    onPressed: () => _navigateToDownloads(),
                  ),
                  if (downloadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Color(0xFFC5A880),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text('$downloadCount', style: TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.analytics, color: Colors.white),
            onPressed: () => _navigateToStats(),
          ),
        ],
      ),
      body: _buildBookGrid(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    return Consumer2<ReadingProvider, OfflineProvider>(
      builder: (context, readingProvider, offlineProvider, child) {
        return BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
            _handleNavigation(index);
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Color(0xFF730000),
          unselectedItemColor: Colors.grey,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.library_books),
              label: 'Library',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  Icon(Icons.download),
                  if (offlineProvider.offlineBooks.isNotEmpty)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(1),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                        constraints: BoxConstraints(minWidth: 12, minHeight: 12),
                        child: Text('${offlineProvider.offlineBooks.length}', style: TextStyle(color: Colors.white, fontSize: 8), textAlign: TextAlign.center),
                      ),
                    ),
                ],
              ),
              label: 'Downloads',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark),
              label: 'Bookmarks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: 'Stats',
            ),
          ],
        );
      },
    );
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 0: // Library - already here
        break;
      case 1: // Downloads
        _navigateToDownloads();
        break;
      case 2: // Bookmarks
        _navigateToBookmarks();
        break;
      case 3: // Stats
        _navigateToStats();
        break;
    }
  }

  void _navigateToDownloads() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => OfflineBooksScreen()));
  }

  void _navigateToBookmarks() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => BookmarksScreen()));
  }

  void _navigateToStats() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ReadingStatsScreen()));
  }
}
