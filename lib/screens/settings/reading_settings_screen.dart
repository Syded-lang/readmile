import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

class ReadingSettingsScreen extends StatelessWidget {
  const ReadingSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Settings'),
        actions: [
          TextButton(
            onPressed: () {
              Provider.of<SettingsProvider>(context, listen: false).resetToDefaults();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildThemeSelector(context, provider),
              const SizedBox(height: 24),
              _buildFontFamilySelector(context, provider),
              const SizedBox(height: 24),
              _buildFontSizeSlider(context, provider),
              const SizedBox(height: 24),
              _buildLineHeightSlider(context, provider),
              const SizedBox(height: 24),
              _buildMarginSlider(context, provider),
              const SizedBox(height: 24),
              _buildTextAlignSelector(context, provider),
              const SizedBox(height: 24),
              _buildPreview(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, SettingsProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: provider.availableThemes.map((theme) {
                return Expanded(
                  child: _buildThemeOption(
                      context,
                      theme.toUpperCase(),
                      theme,
                      provider
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
      BuildContext context, String label, String value, SettingsProvider provider) {
    final isSelected = provider.theme == value;
    Color backgroundColor;
    Color textColor;

    switch (value) {
      case 'sepia':
        backgroundColor = const Color(0xFFF6F0E4);
        textColor = const Color(0xFF2C1810);
        break;
      case 'dark':
        backgroundColor = const Color(0xFF1E1E1E);
        textColor = const Color(0xFFE0E0E0);
        break;
      default:
        backgroundColor = Colors.white;
        textColor = const Color(0xFF212121);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () => provider.updateTheme(value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFontFamilySelector(BuildContext context, SettingsProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Font Family',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: provider.fontFamily,
              items: provider.availableFonts.map((font) {
                return DropdownMenuItem(
                  value: font,
                  child: Text(
                    font,
                    style: TextStyle(fontFamily: font),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  provider.updateFontFamily(value);
                }
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSizeSlider(BuildContext context, SettingsProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Font Size',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text('${provider.fontSize.round()}px'),
              ],
            ),
            Slider(
              value: provider.fontSize,
              min: 12,
              max: 30,
              divisions: 18,
              onChanged: (value) => provider.updateFontSize(value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineHeightSlider(BuildContext context, SettingsProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Line Height',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(provider.lineHeight.toStringAsFixed(1)),
              ],
            ),
            Slider(
              value: provider.lineHeight,
              min: 1.0,
              max: 2.5,
              divisions: 15,
              onChanged: (value) => provider.updateLineHeight(value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarginSlider(BuildContext context, SettingsProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Page Margins',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text('${provider.margin.round()}px'),
              ],
            ),
            Slider(
              value: provider.margin,
              min: 8,
              max: 48,
              divisions: 10,
              onChanged: (value) => provider.updateMargin(value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextAlignSelector(BuildContext context, SettingsProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Text Alignment',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildAlignmentButton(
                  context,
                  Icons.format_align_left,
                  TextAlign.left,
                  provider,
                ),
                _buildAlignmentButton(
                  context,
                  Icons.format_align_center,
                  TextAlign.center,
                  provider,
                ),
                _buildAlignmentButton(
                  context,
                  Icons.format_align_right,
                  TextAlign.right,
                  provider,
                ),
                _buildAlignmentButton(
                  context,
                  Icons.format_align_justify,
                  TextAlign.justify,
                  provider,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlignmentButton(
      BuildContext context, IconData icon, TextAlign align, SettingsProvider provider) {
    final isSelected = provider.textAlign == align;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        child: InkWell(
          onTap: () => provider.updateTextAlign(align),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(SettingsProvider provider) {
    return Card(
      child: Container(
        color: provider.backgroundColor,
        padding: EdgeInsets.all(provider.margin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preview',
              style: TextStyle(
                fontFamily: provider.fontFamily,
                fontSize: provider.fontSize + 2,
                fontWeight: FontWeight.bold,
                color: provider.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This is how your text will appear when reading. You can adjust the font family, size, line height, margins, and alignment to make your reading experience more comfortable.',
              style: TextStyle(
                fontFamily: provider.fontFamily,
                fontSize: provider.fontSize,
                height: provider.lineHeight,
                color: provider.textColor,
              ),
              textAlign: provider.textAlign,
            ),
          ],
        ),
      ),
    );
  }
}