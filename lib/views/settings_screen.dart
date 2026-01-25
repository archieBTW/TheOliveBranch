
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    final colors = [
      Colors.deepPurple, // Lavender-ish
      Colors.blue,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.red,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.merriweather()),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: settings.themeMode == ThemeMode.dark,
            onChanged: (val) {
              settings.toggleTheme(val);
            },
          ),
          ListTile(
            title: const Text('Primary Color'),
            subtitle: Wrap(
              spacing: 8,
              children: colors.map((color) {
                return GestureDetector(
                  onTap: () => settings.setPrimaryColor(color),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: settings.primaryColor == color
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          _buildSectionHeader('News Sources'),
          ...['Sojo', 'Red Letter', 'BNG', 'Christian Century', 'Good Faith Media', 'RNS', 'NCR'].map((source) {
            return SwitchListTile(
              title: Text(source),
              value: settings.isSourceEnabled(source),
              onChanged: (val) => settings.toggleSource(source, val),
            );
          }),
          const Divider(),
          _buildSectionHeader('Music Sources'),
          ...['IVM', 'HM Mag', 'Relevant'].map((source) {
            return SwitchListTile(
              title: Text(source),
              value: settings.isSourceEnabled(source),
              onChanged: (val) => settings.toggleSource(source, val),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
