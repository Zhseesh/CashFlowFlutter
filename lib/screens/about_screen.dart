import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  bool _checking = false;

  Future<void> _checkUpdate() async {
    setState(() => _checking = true);
    try {
      final response = await http.get(Uri.parse('https://api.github.com/repos/Zhseesh/CashFlowFlutter/releases/latest'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestVersion = data['tag_name'].toString().replaceAll('v', '');
        final htmlUrl = data['html_url'].toString();
        
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        if (!mounted) return;

        if (latestVersion != currentVersion) {
          // Update Tersedia
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Update Tersedia!'),
              content: Text('Versi terbaru ($latestVersion) tersedia di GitHub. Versi kamu saat ini: $currentVersion.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Nanti')),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    launchUrl(Uri.parse(htmlUrl), mode: LaunchMode.externalApplication);
                  },
                  child: const Text('Buka GitHub'),
                ),
              ],
            ),
          );
        } else {
          // Up to date
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Aplikasi Up-to-Date'),
              content: Text('Kamu sudah menggunakan versi terbaru ($currentVersion).'),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
            ),
          );
        }
      } else {
        throw Exception('Gagal mengambil data rilis');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal cek update: $e')));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang Aplikasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.account_balance_wallet, size: 48, color: Color(0xFF10B981)),
              ),
              const SizedBox(height: 24),
              const Text('Cash Flow', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text('Versi ${snapshot.data!.version}+${snapshot.data!.buildNumber}', style: TextStyle(color: Colors.grey.shade500));
                  }
                  return const SizedBox();
                },
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _checking ? null : _checkUpdate,
                  icon: _checking ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.system_update),
                  label: Text(_checking ? 'Memeriksa...' : 'Cek Pembaruan'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                    side: const BorderSide(color: Color(0xFF10B981)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Dibuat dengan ❤️ menggunakan Flutter',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
              )
            ],
          ),
        ),
      ),
    );
  }
}