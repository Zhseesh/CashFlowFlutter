import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.translate('settings'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionTitle(l10n.translate('appearance')),
          _buildMaterialWrapper(
            isDark: isDark,
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeManager.themeMode,
              builder: (context, mode, _) {
                String currentText = mode == ThemeMode.system 
                    ? l10n.translate('system')
                    : mode == ThemeMode.light 
                        ? l10n.translate('light') 
                        : l10n.translate('dark');

                return PopupMenuButton<ThemeMode>(
                  position: PopupMenuPosition.under, 
                  tooltip: '', 
                  initialValue: mode,
                  onSelected: (v) => ThemeManager.setTheme(v),
                  itemBuilder: (context) => [
                    PopupMenuItem(value: ThemeMode.system, child: Text(l10n.translate('system'))),
                    PopupMenuItem(value: ThemeMode.light, child: Text(l10n.translate('light'))),
                    PopupMenuItem(value: ThemeMode.dark, child: Text(l10n.translate('dark'))),
                  ],
                  child: ListTile(
                    leading: const Icon(LucideIcons.palette, color: Color(0xFF10B981)),
                    title: Text(l10n.translate('appearance'), style: const TextStyle(fontSize: 14)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min, 
                      children: [
                        Text(
                          currentText,
                          style: TextStyle(
                            fontSize: 13, 
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(LucideIcons.chevronDown, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 24),
          _buildSectionTitle(l10n.translate('language')),
          _buildMaterialWrapper(
            isDark: isDark,
            child: ValueListenableBuilder<Locale>(
              valueListenable: ThemeManager.locale,
              builder: (context, loc, _) {
                String currentText = loc.languageCode == 'id' 
                    ? l10n.translate('indonesian') 
                    : l10n.translate('english');

                return PopupMenuButton<String>(
                  position: PopupMenuPosition.under, 
                  tooltip: '', 
                  initialValue: loc.languageCode,
                  onSelected: (v) => ThemeManager.setLocale(v),
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'id', child: Text(l10n.translate('indonesian'))),
                    PopupMenuItem(value: 'en', child: Text(l10n.translate('english'))),
                  ],
                  child: ListTile(
                    leading: const Icon(LucideIcons.globe, color: Color(0xFF10B981)),
                    title: Text(l10n.translate('language'), style: const TextStyle(fontSize: 14)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min, 
                      children: [
                        Text(
                          currentText,
                          style: TextStyle(
                            fontSize: 13, 
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(LucideIcons.chevronDown, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionTitle(l10n.translate('features')),
          _buildMaterialWrapper(
            isDark: isDark,
            child: ListTile(
              leading: const Icon(LucideIcons.pieChart, color: Color(0xFF10B981)),
              title: Text(l10n.translate('budget'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(l10n.translate('budget_sub'), style: const TextStyle(fontSize: 11)),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetScreen())),
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionTitle(l10n.translate('others')),
          _buildMaterialWrapper(
            isDark: isDark,
            child: ListTile(
              leading: const Icon(LucideIcons.info, color: Color(0xFF10B981)),
              title: Text(l10n.translate('about'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(l10n.translate('about_sub'), style: const TextStyle(fontSize: 11)),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialWrapper({required bool isDark, required Widget child}) {
    return Material(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias, 
      child: child,
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