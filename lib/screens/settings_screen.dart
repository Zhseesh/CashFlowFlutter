import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../utils/theme_manager.dart';
import 'about_screen.dart';
import 'budget_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('settings'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionTitle(l10n.translate('appearance')),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ValueListenableBuilder<ThemeMode>(
                valueListenable: ThemeManager.themeMode,
                builder: (context, mode, _) {
                  return RadioGroup<ThemeMode>(
                    groupValue: mode,
                    onChanged: (v) => ThemeManager.setTheme(v!),
                    child: Column(
                      children: [
                        RadioListTile<ThemeMode>(
                          title: Text(l10n.translate('system'), style: const TextStyle(fontSize: 14)),
                          value: ThemeMode.system,
                          activeColor: const Color(0xFF10B981),
                        ),
                        RadioListTile<ThemeMode>(
                          title: Text(l10n.translate('light'), style: const TextStyle(fontSize: 14)),
                          value: ThemeMode.light,
                          activeColor: const Color(0xFF10B981),
                        ),
                        RadioListTile<ThemeMode>(
                          title: Text(l10n.translate('dark'), style: const TextStyle(fontSize: 14)),
                          value: ThemeMode.dark,
                          activeColor: const Color(0xFF10B981),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          _buildSectionTitle(l10n.translate('language')),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ValueListenableBuilder<Locale>(
                valueListenable: ThemeManager.locale,
                builder: (context, loc, _) {
                  return RadioGroup<String>(
                    groupValue: loc.languageCode,
                    onChanged: (v) => ThemeManager.setLocale(v!),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title: Text(l10n.translate('indonesian'), style: const TextStyle(fontSize: 14)),
                          value: 'id',
                          activeColor: const Color(0xFF10B981),
                        ),
                        RadioListTile<String>(
                          title: Text(l10n.translate('english'), style: const TextStyle(fontSize: 14)),
                          value: 'en',
                          activeColor: const Color(0xFF10B981),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionTitle(l10n.translate('features')),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ListTile(
                leading: const Icon(Icons.pie_chart_outline, color: Color(0xFF10B981)),
                title: Text(l10n.translate('budget'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(l10n.translate('budget_sub'), style: const TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetScreen())),
              ),
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionTitle(l10n.translate('others')),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ListTile(
                leading: const Icon(Icons.info_outline, color: Color(0xFF10B981)),
                title: Text(l10n.translate('about'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(l10n.translate('about_sub'), style: const TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      title.toUpperCase(),
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey.shade500),
    ),
  );
}