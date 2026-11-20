import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../l10n/app_localizations.dart';
import '../theme/neo_theme.dart';
import '../utils/theme_manager.dart';
import 'about_screen.dart';
import 'budget_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ink = Neo.ink(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.translate('settings'),
            style: NeoText.display(18, color: ink)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionTitle(l10n.translate('appearance'), ink),
          _buildNeoWrapper(
            context,
            ink,
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
                    PopupMenuItem(
                        value: ThemeMode.system,
                        child: Text(l10n.translate('system'))),
                    PopupMenuItem(
                        value: ThemeMode.light,
                        child: Text(l10n.translate('light'))),
                    PopupMenuItem(
                        value: ThemeMode.dark,
                        child: Text(l10n.translate('dark'))),
                  ],
                  child: _buildSettingTile(
                    context,
                    ink,
                    icon: LucideIcons.palette,
                    iconBg: NeoColors.yellow,
                    title: l10n.translate('appearance'),
                    value: currentText,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle(l10n.translate('language'), ink),
          _buildNeoWrapper(
            context,
            ink,
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
                    PopupMenuItem(
                        value: 'id',
                        child: Text(l10n.translate('indonesian'))),
                    PopupMenuItem(
                        value: 'en',
                        child: Text(l10n.translate('english'))),
                  ],
                  child: _buildSettingTile(
                    context,
                    ink,
                    icon: LucideIcons.globe,
                    iconBg: NeoColors.cyan,
                    title: l10n.translate('language'),
                    value: currentText,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle(l10n.translate('features'), ink),
          GestureDetector(
            onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const BudgetScreen())),
            child: _buildNeoWrapper(
              context,
              ink,
              child: _buildSettingTile(
                context,
                ink,
                icon: LucideIcons.pieChart,
                iconBg: NeoColors.purple,
                title: l10n.translate('budget'),
                subtitle: l10n.translate('budget_sub'),
                trailing: Icon(LucideIcons.chevronRight, size: 18, color: ink),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle(l10n.translate('others'), ink),
          GestureDetector(
            onTap: () => Navigator.push(context, 
                MaterialPageRoute(builder: (_) => const AboutScreen())),
            child: _buildNeoWrapper(
              context,
              ink,
              child: _buildSettingTile(
                context,
                ink,
                icon: LucideIcons.info,
                iconBg: NeoColors.pink,
                title: l10n.translate('about'),
                subtitle: l10n.translate('about_sub'),
                trailing: Icon(LucideIcons.chevronRight, size: 18, color: ink),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeoWrapper(
      BuildContext context, Color ink, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Neo.paper(context),
        borderRadius: BorderRadius.circular(NeoRadius.lg),
        border: NeoBorders.reg(ink),
        boxShadow: NeoShadows.sm(ink),
      ),
      child: child,
    );
  }

  Widget _buildSettingTile(
    BuildContext context,
    Color ink, {
    required IconData icon,
    required Color iconBg,
    required String title,
    String? subtitle,
    String? value,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              border: NeoBorders.thin(ink),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: NeoColors.inkLight),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: NeoText.body(14, weight: FontWeight.w700, color: ink)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style:
                          NeoText.label(9, color: ink.withValues(alpha: 0.6))),
                ],
              ],
            ),
          ),
          if (value != null) ...[
            Text(value,
                style: NeoText.label(11, color: ink.withValues(alpha: 0.7))),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronDown, size: 16,
                color: ink.withValues(alpha: 0.7)),
          ],
          ?trailing,
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color ink) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title.toUpperCase(), style: NeoText.label(10, color: ink)),
      );
}