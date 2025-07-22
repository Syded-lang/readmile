import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF730000),
        foregroundColor: Colors.white,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection(
                'Reading Appearance',
                [
                  _buildThemeSelector(context, settings),
                  _buildFontSizeSlider(settings),
                  _buildFontFamilyDropdown(settings),
                  _buildLineHeightSlider(settings),
                  _buildMarginSlider(settings),
                  _buildTextAlignSelector(settings),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                'App Settings',
                [
                  _buildNightModeToggle(settings),
                  _buildBrightnessSlider(settings),
                ],
              ),
              const SizedBox(height: 24),
              _buildResetButton(context, settings),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF730000),
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, SettingsProvider settings) {
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

  Widget _buildTextAlignSelector(SettingsProvider settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Text Alignment'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildAlignChip('Left', TextAlign.left, settings),
            _buildAlignChip('Center', TextAlign.center, settings),
            _buildAlignChip('Right', TextAlign.right, settings),
            _buildAlignChip('Justify', TextAlign.justify, settings),
          ],
        ),
      ],
    );
  }

  Widget _buildAlignChip(String label, TextAlign align, SettingsProvider settings) {
    final isSelected = settings.textAlign == align;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          settings.setTextAlign(align);
        }
      },
      selectedColor: const Color(0xFF730000).withOpacity(0.2),
    );
  }

  Widget _buildNightModeToggle(SettingsProvider settings) {
    return SwitchListTile(
      title: const Text('Night Mode'),
      subtitle: const Text('Automatically switch to dark theme'),
      value: settings.nightMode,
      onChanged: (value) => settings.toggleNightMode(),
      activeColor: const Color(0xFF730000),
    );
  }

  Widget _buildBrightnessSlider(SettingsProvider settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Brightness: ${(settings.brightness * 100).round()}%'),
        Slider(
          value: settings.brightness,
          min: 0.3,
          max: 1.0,
          onChanged: (value) => settings.setBrightness(value),
          activeColor: const Color(0xFF730000),
        ),
      ],
    );
  }

  Widget _buildResetButton(BuildContext context, SettingsProvider settings) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Reset Settings'),
              content: const Text('Are you sure you want to reset all settings to default?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    settings.resetToDefaults();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings reset to defaults')),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF730000)),
                  child: const Text('Reset', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        child: const Text('Reset to Defaults'),
      ),
    );
  }

  String _capitalizeFirst(String text) {
    return text[0].toUpperCase() + text.substring(1);
  }
}
