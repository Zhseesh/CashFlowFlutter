import 'package:flutter/material.dart';
import '../utils/theme_manager.dart';
import 'about_screen.dart';
import 'budget_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionTitle('Tampilan'),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
            ),
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeManager.themeMode,
              builder: (context, mode, _) {
                return RadioGroup<ThemeMode>(
                  groupValue: mode,
                  onChanged: (v) => ThemeManager.setTheme(v!),
                  child: const Column(
                    children: [
                      RadioListTile<ThemeMode>(
                        title: Text('Ikuti Sistem', style: TextStyle(fontSize: 14)),
                        value: ThemeMode.system,
                        activeColor: Color(0xFF10B981),
                      ),
                      RadioListTile<ThemeMode>(
                        title: Text('Terang', style: TextStyle(fontSize: 14)),
                        value: ThemeMode.light,
                        activeColor: Color(0xFF10B981),
                      ),
                      RadioListTile<ThemeMode>(
                        title: Text('Gelap', style: TextStyle(fontSize: 14)),
                        value: ThemeMode.dark,
                        activeColor: Color(0xFF10B981),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 24),
          _buildSectionTitle('Bahasa'),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
            ),
            child: ValueListenableBuilder<Locale>(
              valueListenable: ThemeManager.locale,
              builder: (context, loc, _) {
                return RadioGroup<String>(
                  groupValue: loc.languageCode,
                  onChanged: (v) => ThemeManager.setLocale(v!),
                  child: const Column(
                    children: [
                      RadioListTile<String>(
                        title: Text('Bahasa Indonesia', style: TextStyle(fontSize: 14)),
                        value: 'id',
                        activeColor: Color(0xFF10B981),
                      ),
                      RadioListTile<String>(
                        title: Text('English', style: TextStyle(fontSize: 14)),
                        value: 'en',
                        activeColor: Color(0xFF10B981),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionTitle('Fitur'),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
            ),
            child: ListTile(
              leading: const Icon(Icons.pie_chart_outline, color: Color(0xFF10B981)),
              title: const Text('Atur Anggaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Batas maksimal pengeluaran per kategori', style: TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetScreen())),
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionTitle('Lainnya'),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
            ),
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: Color(0xFF10B981)),
              title: const Text('Tentang Aplikasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Versi, informasi, & cek update', style: TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
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