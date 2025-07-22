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
        backgroundColor: const Color(0xFF730000),
        foregroundColor: Colors.white,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return Container(
            color: settings.backgroundColor,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPreviewCard(settings),
                const SizedBox(height: 24),
                _buildSettingsCard(settings),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPreviewCard(SettingsProvider settings) {
    return Card(
      color: settings.backgroundColor,
      child: Padding(
        padding: EdgeInsets.all(settings.margin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: settings.textColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This is how your text will appear while reading. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
              style: TextStyle(
                fontSize: settings.fontSize,
                fontFamily: settings.fontFamily,
                height: settings.lineHeight,
                color: settings.textColor,
              ),
              textAlign: settings.textAlign,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(SettingsProvider settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
            const SizedBox(height: 16),
            _buildFontSizeSlider(settings),
            const SizedBox(height: 16),
            _buildFontFamilyDropdown(settings),
            const SizedBox(height: 16),
            _buildLineHeightSlider(settings),
            const SizedBox(height: 16),
            _buildMarginSlider(settings),
            const SizedBox(height: 16),
            _buildThemeSelector(settings),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSizeSlider(SettingsProvider settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Font Size: ${settings.fontSize.round()}'),
        Slider(
          value: settings.fontSize,
          min: 12,
          max: 24,
          divisions: 12,
          onChanged: (value) => settings.setFontSize(value),
          activeColor: const Color(0xFF730000),
        ),
      ],
    );
  }

  Widget _buildFontFamilyDropdown(SettingsProvider settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Font Family'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: settings.fontFamily,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: settings.availableFontFamilies.map((font) {
            return DropdownMenuItem(
              value: font,
              child: Text(font, style: TextStyle(fontFamily: font)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              settings.setFontFamily(value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildLineHeightSlider(SettingsProvider settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Line Height: ${settings.lineHeight.toStringAsFixed(1)}'),
        Slider(
          value: settings.lineHeight,
          min: 1.0,
          max: 2.0,
          divisions: 10,
          onChanged: (value) => settings.setLineHeight(value),
          activeColor: const Color(0xFF730000),
        ),
      ],
    );
  }

  Widget _buildMarginSlider(SettingsProvider settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Margin: ${settings.margin.round()}'),
        Slider(
          value: settings.margin,
          min: 8,
          max: 32,
          divisions: 12,
          onChanged: (value) => settings.setMargin(value),
          activeColor: const Color(0xFF730000),
        ),
      ],
    );
  }

  Widget _buildThemeSelector(SettingsProvider settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Theme'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: settings.availableThemes.map((theme) {
            final isSelected = settings.theme == theme;
            return ChoiceChip(
              label: Text(_capitalizeFirst(theme)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  settings.setTheme(theme);
                }
              },
              selectedColor: const Color(0xFF730000).withOpacity(0.2),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _capitalizeFirst(String text) {
    return text[0].toUpperCase() + text.substring(1);
  }
}
