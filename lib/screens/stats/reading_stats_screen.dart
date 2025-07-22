import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/reading_provider.dart';
import '../../providers/book_provider.dart';

class ReadingStatsScreen extends StatelessWidget {
  const ReadingStatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Statistics'),
      ),
      body: Consumer<ReadingProvider>(
        builder: (context, readingProvider, child) {
          final progress = readingProvider.readingProgress;
          final bookProvider = Provider.of<BookProvider>(context);

          if (progress.isEmpty) {
            return const Center(
              child: Text('No reading data available yet'),
            );
          }

          final totalBooks = progress.length;
          final completedBooks = progress
              .where((p) => p.readPercentage >= 0.99)
              .length;

          final averageCompletion = progress.isEmpty
              ? 0.0
              : progress.map((p) => p.readPercentage).reduce((a, b) => a + b) / progress.length;

          final totalReadingTime = progress.fold<int>(
              0, (sum, p) => sum + p.totalTimeSpentInSeconds);

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSummaryCard(
                  context,
                  totalBooks,
                  completedBooks,
                  averageCompletion
              ),
              const SizedBox(height: 20),

              _buildReadingTimeCard(context, totalReadingTime),

              const SizedBox(height: 20),
              _buildRecentlyReadList(context, progress, bookProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, int totalBooks, int completedBooks, double averageCompletion) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            _buildStatRow('Total Books', '$totalBooks'),
            _buildStatRow('Completed Books', '$completedBooks'),
            _buildStatRow('Average Completion', '${(averageCompletion * 100).toStringAsFixed(1)}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingTimeCard(BuildContext context, int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Reading Time',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '${hours}h ${minutes}m',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentlyReadList(BuildContext context, List<dynamic> progress, BookProvider bookProvider) {
    final sorted = List.from(progress)
      ..sort((a, b) => b.lastReadAt.compareTo(a.lastReadAt));

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recently Read',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sorted.length > 5 ? 5 : sorted.length,
              itemBuilder: (context, index) {
                final item = sorted[index];
                final book = bookProvider.getBookById(item.bookId);

                if (book == null) {
                  return const SizedBox.shrink();
                }

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(book.title),
                  subtitle: Text(book.author),
                  trailing: Text(
                    '${(item.readPercentage * 100).toStringAsFixed(0)}%',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}