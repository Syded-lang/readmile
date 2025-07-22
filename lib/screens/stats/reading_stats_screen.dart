import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/reading_provider.dart';
import '../../providers/book_provider.dart';

class ReadingStatsScreen extends StatelessWidget {
  const ReadingStatsScreen({Key? key}) : super(key: key);

  // Performance optimization: Define colors as static constants
  static const Color _primaryColor = Color(0xFF730000);
  static const Color _secondaryColor = Color(0xFFC5A880);
  static const Color _backgroundColor = Color(0xFFFAF9F7);
  static const Color _textPrimary = Color(0xFF2D2D2D);
  static const Color _textSecondary = Color(0xFF6B6B6B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Reading Statistics',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _primaryColor,
      ),
      body: Consumer<ReadingProvider>(
        builder: (context, readingProvider, child) {
          final progress = readingProvider.readingProgress;
          final bookProvider = Provider.of<BookProvider>(context);

          if (progress.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_stories_outlined,
                    size: 80,
                    color: _textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No reading data available yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: _textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start reading to see your statistics',
                    style: TextStyle(
                      fontSize: 14,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          final totalBooks = progress.length;
          final completedBooks = progress
              .where((p) => p.readPercentage >= 0.99)
              .length;

          final averageCompletion = progress.isEmpty
              ? 0.0
              : progress.map((p) => p.readPercentage).reduce((a, b) => a + b) / progress.length;

          // Fixed: Ensure the result is int by using toInt()
          final totalReadingTime = progress.fold<num>(
              0, (sum, p) => sum + p.totalTimeSpentInSeconds).toInt();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverviewCards(
                  context,
                  totalBooks,
                  completedBooks,
                  averageCompletion,
                ),
                const SizedBox(height: 24),
                _buildReadingTimeCard(context, totalReadingTime),
                const SizedBox(height: 24),
                _buildRecentlyReadCard(context, progress, bookProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewCards(BuildContext context, int totalBooks, int completedBooks, double averageCompletion) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                icon: Icons.library_books,
                iconColor: _primaryColor,
                title: 'Total Books',
                value: '$totalBooks',
                subtitle: 'books started',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                context,
                icon: Icons.check_circle,
                iconColor: _secondaryColor,
                title: 'Completed',
                value: '$completedBooks',
                subtitle: 'books finished',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildProgressCard(context, averageCompletion),
      ],
    );
  }

  Widget _buildMetricCard(
      BuildContext context, {
        required IconData icon,
        required Color iconColor,
        required String title,
        required String value,
        required String subtitle,
      }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _textSecondary,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, double averageCompletion) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: _primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${(averageCompletion * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                  Text(
                    'Average Progress',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: averageCompletion,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(_primaryColor),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildReadingTimeCard(BuildContext context, int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_secondaryColor, _primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.access_time,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            'Total Reading Time',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${hours}h ${minutes}m',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyReadCard(BuildContext context, List<dynamic> progress, BookProvider bookProvider) {
    final sorted = List.from(progress)
      ..sort((a, b) => b.lastReadAt.compareTo(a.lastReadAt));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history,
                color: _primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Recently Read',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sorted.length > 5 ? 5 : sorted.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = sorted[index];
              final book = bookProvider.getBookById(item.bookId);

              if (book == null) {
                return const SizedBox.shrink();
              }

              final progressPercentage = (item.readPercentage * 100).toStringAsFixed(0);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _secondaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.book,
                        color: _secondaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: _textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            book.author,
                            style: TextStyle(
                              color: _textSecondary,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getProgressColor(item.readPercentage).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$progressPercentage%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getProgressColor(item.readPercentage),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.99) return _secondaryColor;
    if (progress >= 0.5) return const Color(0xFFE67E22);
    return _primaryColor;
  }
}